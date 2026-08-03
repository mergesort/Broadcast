# Broadcast

### Simple and composable logging for Swift apps, servers, and coding agents.

Broadcast is a structured logging library for Swift apps and servers that feels as lightweight as `print`, but gives every log enough structure to help you solve real production issues.

Broadcast turns simple logs like `log.info("Started app")` into a trail of actions and state that can be sent to your console, saved to support logs, or optimized for coding agents.

---

Broadcast is already running in production in [Plinky](https://plinky.app), where it's helped Codex track down bugs and race conditions I'd been chasing for over a year. By handing an agent thousands of structured logs you take the guesswork out of debugging. Instead your coding agent can trace through and debug problems on its own, with far less help from you.

By integrating Broadcast from day one you'll give coding agents the feedback loop they need while they work, leading to fewer bugs and less time reviewing slop.

## Table of Contents

- [Getting Started](#getting-started)
- [Structured Logs](#structured-logs)
- [Destinations](#destinations)
- [swift-log](#swift-log)
- [Formatting](#formatting)
- [Documentation](#documentation)
- [Coding Agent Plugins](#coding-agent-plugins)
- [Requirements](#requirements)
- [Installation](#installation)
- [Feedback & Contribution](#feedback--contribution)

## Getting Started

Broadcast starts with one type: `Log`. A `Log` owns one or more destinations, so every call to `log.debug`, `log.info`, `log.error`, etc. is sent to each destination.

```swift
import Broadcast

// Instantiate a ConsoleLogger that logs to Xcode's console
let consoleLogger = ConsoleLogger(subsystem: "com.example.app", category: "logs")

// Instantiate a SessionLogger that logs to an in-memory buffer that you can later export from
let sessionLogger = SessionLogger()

let log = Log(
	destinations: [
		consoleLogger,
		sessionLogger
	]
)

log.info("Started app")
log.debug("Synced", 10, "links")
```

That's it. You now have one API that writes to the console and keeps an in-memory support log you can export later.

```swift
let supportLogs = sessionLogger.logs()
```

> [!TIP]
> I recommend creating one global `let log` for your app or package so you can call `log.info(...)` everywhere and make your call-sites clean and simple.

Broadcast is intentionally not prescriptive, so you can still pass `Log` through dependency injection, expose the same global logger through the SwiftUI environment, or use whatever access pattern fits your app. The important part is that your app has one easy logging API, and destinations decide where those logs go.

## Structured Logs

Logging plain strings is useful for quick local debugging, but structured logs provide the context you need to fix complicated problems. We can do so by using typed values like `Log.Signal`, `Log.Category`, and `Log.Payload` to add context for future debugging sessions.

```swift
log.info(
	.state,
	"Synced links",
	category: .sync,
	payload: [
		.result("Success"),
		.linkCount(links.count)
	]
)
```

Broadcast's structured log is composed of a few primitives:

- `Log.Level`: `debug`, `info`, `warn`, `error`, or `fault`.
- `Log.Signal`: Describes what change occurred, such as an `.action`, `.state`, `.event`, `.metric`, or `.diagnostic`.
- `Log.Category`: Describes what part or subsystem of your app this log is tied to, such as `"Sync"`, `"Account"`, or `"Payments"`.
- `Log.Payload`: Typed key-value diagnostics like identifiers, counts, dates, durations, and errors.

You can keep call-sites readable by adding properties and functions that represent signals, categories, and payloads unique to your app:

```swift
extension Log.Category {
	static let sync: Self = "Sync"
}

extension Log.Payload {
	static func result(_ result: String) -> Self {
		Self.string("result", result)
	}

	static func accountID(_ id: UUID) -> Self {
		Self.uuid("accountID", id)
	}

	static func linkCount(_ count: Int) -> Self {
		Self.int("linkCount", count)
	}
}

log.info(
	.action,
	"Finished account sync",
	category: .sync,
	payload: [
		.accountID(account.id),
		.linkCount(links.count),
		.duration(seconds: syncDuration)
	]
)
```

## Destinations

Broadcast includes a few destinations out of the box:

- `ConsoleLogger` writes to Apple's unified logging system.
- `SessionLogger` buffers logs in memory for the current launch.
- `MultiSessionLogger` buffers logs across launches using a [Boutique](https://github.com/mergesort/boutique) `Store`.

Destinations are composable, so one call-site can power multiple debugging workflows.

```swift
let supportLogger = SessionLogger(
	timestampFormatStyle: .timestamp
)

// Optionally persist logs across launches
let logStore = try await Store<Log.Record>(
	storage: SQLiteStorageEngine.default(appendingPath: "Logs")
)

let multiSessionLogger = MultiSessionLogger(store: logStore)

let log = Log(
	destinations: [
		ConsoleLogger(subsystem: "com.example.app", category: "logs"),
		supportLogger,
		multiSessionLogger
	]
)
```

You can also append a new `LoggingDestination` to an existing `Log`, returning a new `Log` that sends records to more destinations without having to make global changes.

```swift
let syncDiagnostics = SessionLogger(timestampFormatStyle: .timestamp)
let syncLog = log.combined(with: syncDiagnostics)

syncLog.info(
	.action,
	"Started sync",
	category: "Sync",
	payload: [
		.string("reason", "AppLaunch")
	]
)
```

Create a custom destination by conforming to `LoggingDestination` and implementing `log(_:)` for each `Log.Record`.

```swift
final class UploadLoggingDestination: LoggingDestination {
	func log(_ record: Log.Record) {
		let text = record.formatted(.json)
		// Upload, save, print, enqueue, or do anything you want with the rendered record.
	}
}
```

## swift-log

Broadcast can forward records to [apple/swift-log](https://github.com/apple/swift-log) when you enable the `SwiftLogging` package trait. This lets Broadcast stay as the call-site API while a server or app still writes to whatever swift-log backend it has configured.

```swift
import Broadcast

let log = Log(
	destinations: [
		SessionLogger(),
		SwiftLogDestination(label: "com.example.app")
	]
)

log.info(
	.state,
	"Synced links",
	category: "Sync",
	payload: [
		.count(10)
	]
)
```

`SwiftLogDestination` maps Broadcast levels to swift-log levels and forwards record details as metadata. Broadcast's record identifier, timestamp, signal, and category use `broadcast.*` keys, and payload values use `payload.*` keys.

## Formatting

Broadcast treats `Log.Record` as the source of truth for logs, and asks destinations to format their logs.

```swift
import Foundation

let record = Log.Record(
	timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
	level: .info,
	signal: .state,
	message: "Synced links",
	category: "Sync",
	payload: [
		.int("linkCount", 10),
		.int("tagCount", 5)
	]
)

record.formatted(.default)
record.formatted(.json)
record.formatted(.canonicalLogLine)
record.formatted(.tokenOptimized)
```

The built-in formats cover common cases.

`.default`: A human-readable log format.

```text
[Info | State | Sync] @ 1970-01-01T00:00:42Z | Synced links | payload=[linkCount=10, tagCount=5]
```

`.json`: For inspection with JSON tools.

```json
{
  "timestamp": "1970-01-01T00:00:42Z",
  "level": "info",
  "signal": "State",
  "category": "Sync",
  "message": "Synced links",
  "payload": {
    "linkCount": 10,
    "tagCount": 5
  }
}
```

`.canonicalLogLine`: A dense key-value text inspired by [Stripe's canonical log lines](https://stripe.com/blog/canonical-log-lines).

```text
[1970-01-01T00:00:42Z] canonical-log-line level=info signal=State category=Sync message="Synced links" linkCount=10 tagCount=5
```

`.tokenOptimized`: A compact log format designed to optimize AI context windows.

```text
t=42000 l=info s=State c=Sync m="Synced links" p.linkCount=10 p.tagCount=5
```

---

If Broadcast's built-in formats are not the right fit for your needs, you can define a custom `FormatStyle`. You can even provide different shapes on a per-export basis:

```swift
import Foundation

struct SupportFormatStyle: Foundation.FormatStyle, Sendable {
	func format(_ value: Log.Record) -> String {
		[
			value.level.rawValue,
			value.signal?.identifier,
			value.category?.identifier,
			value.message
		]
		.compactMap({ $0 })
		.filter({ !$0.isEmpty })
		.joined(separator: " | ")
	}
}

extension FormatStyle where Self == SupportFormatStyle {
	static var support: Self {
		Self()
	}
}

let supportLogs = sessionLogger.records()
	.map({ $0.formatted(.support) })
	.joined(separator: "\n")
```

## Documentation

Broadcast includes DocC documentation in [`Sources/Broadcast/Documentation.docc`](Sources/Broadcast/Documentation.docc).

The documentation goes deeper into:

- Choosing destinations
- Creating structured payload vocabulary
- Exporting logs for support and AI debugging
- Building custom record formats
- Testing logging behavior

To generate the docs locally from the repository root:

```bash
swift package generate-documentation --target Broadcast
```

Using this command rather than `xcrun docc convert` will build Broadcast's symbol graph before converting the DocC catalog, which is required for symbol links like ``Log`` and ``SessionLogger`` to resolve correctly.

## Coding Agent Plugins

Broadcast includes [Claude Code](https://claude.ai/code) and [Codex](https://developers.openai.com/codex) plugins. These skills will help your coding agents integrate Broadcast into your app, follow the recommended logging patterns, and avoid inventing APIs that do not exist.

### Claude Code

If you have cloned the Broadcast repo locally, Claude Code can discover the plugin from the repo's marketplace metadata. Otherwise run:

```
/plugin marketplace add mergesort/Broadcast
/plugin install broadcast@broadcast
/reload-plugins
```

### Codex

If you have cloned the Broadcast repo locally, Codex can discover the plugin from the repo's marketplace metadata. Otherwise run:

```
codex plugin marketplace add mergesort/Broadcast
```

## Requirements

- iOS 18.0+
- macOS 15.0+
- Xcode 16.3+

## Installation

### Swift Package Manager

Add Broadcast to your package dependencies:

```swift
dependencies: [
.package(url: "https://github.com/mergesort/Broadcast", from: Version(1, 0, 0))
]
```

To enable the swift-log destination, enable Broadcast's `SwiftLogging` trait:

```swift
dependencies: [
	.package(
		url: "https://github.com/mergesort/Broadcast",
		from: Version(1, 0, 0),
		traits: ["SwiftLogging"]
	)
]
```

## Feedback & Contribution

Broadcast is relatively new, but it's already a very powerful tool.

- If you have a question about Broadcast, please check the documentation first.
- If you still have a question, suggestion, or way to improve Broadcast, [GitHub Discussions](https://github.com/mergesort/broadcast/discussions) are the right place to share your thoughts.
- If you find a bug, please report it by [creating an issue](https://github.com/mergesort/broadcast/issues).

### About me

Hi, I'm [Joe](http://fabisevi.ch) everywhere on the web, but especially on [Bluesky](https://bsky.app/profile/mergesort.me).

### Sponsorship

Broadcast is a labor of love to help developers build better apps, making it easier for you to understand what your software is doing and make something better for your users.

If you find Broadcast valuable I would really appreciate it if you'd consider helping [sponsor my open source work](https://github.com/sponsors/mergesort), so I can continue to work on projects like Broadcast to help developers like yourself.
