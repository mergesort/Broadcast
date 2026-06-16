# Broadcast

### Simple and composable logging for Swift apps, servers, and coding agents.

Broadcast is a structured logging library for Swift apps and servers that feels as lightweight as `print`, but gives every log enough structure to help you solve real production issues.

You still write simple calls like `log.info("Started app")`, but Broadcast turns them into records that can be sent to your console, saved for support logs, exported as JSON, or formatted for AI coding agents.

---

Broadcast makes it possible to capture a user's journey across actions, state changes, network decisions, metrics, and errors. The context around those moments is preserved in typed payloads, which can be exported through human-readable logs, JSON, or token-optimized records.

Broadcast is already running in production in [Plinky](https://plinky.app), where it's helped Codex track down race conditions and edge-case bugs I'd been chasing for over a year. When you can hand an agent thousands of structured logs that document real runtime behavior, it no longer has to guess what your app did. Instead, it can trace through and debug problems with far less help from you, often completely autonomously.

By integrating Broadcast from day one, you give coding agents the context they usually lack when they're building your app. Broadcast provides agents with a feedback loop while they work, which means fewer bugs and less time reviewing slop.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Structured Logs](#structured-logs)
- [Destinations](#destinations)
- [Formatting](#formatting)
- [Documentation](#documentation)
- [Coding Agent Plugins](#coding-agent-plugins)
- [Requirements](#requirements)
- [Installation](#installation)
- [Feedback & Contribution](#feedback--contribution)

---

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
> I recommend creating one shared `Log` so you can call `log.info(...)` everywhere and make your call-sites clean and simple.

Broadcast is intentionally not prescriptive, so if you prefer you can use dependency injection, the SwiftUI environment, or whatever your preferred method for accessing a logger would be. The important part is that your app has one easy logging API, and destinations decide where those logs go.

---

## Structured Logs

Logging plain strings is useful for quick local debugging, but structured logs give you the context you'll need to fix complicated problems after the fact. You can make support exports, remote logs, and AI debugging sessions more useful by attaching metadata to each record.

```swift
log.info(
	.state,
	"Synced links",
	category: .sync,
	payload: [
		.result(.success),
		.linkCount(links.count)
	]
)
```

Broadcast's structured log has a few pieces:

- `Log.Level`: `debug`, `info`, `warn`, `error`, or `fault`.
- `Log.Signal`: what kind of thing happened, such as `.action`, `.state`, `.event`, `.metric`, or `.diagnostic`.
- `Log.Category`: the part of your app this belongs to, such as `"Sync"`, `"Account"`, or `"Payments"`.
- `Log.Payload`: typed key-value diagnostics like identifiers, counts, dates, durations, and errors.

You can keep call-sites readable by adding app-specific vocabulary in your own app or package:

```swift
extension Log.Category {
	static let sync: Self = "Sync"
}

extension Log.Payload {
	static func accountID(_ id: UUID) -> Self {
		Self(key: "accountID", value: id)
	}

	static func linkCount(_ count: Int) -> Self {
		Self(key: "linkCount", value: count)
	}
}

log.info(
	.action,
	"Finished account sync",
	category: .sync,
	payload: [
		.accountID(account.id),
		.linkCount(links.count),
		.init(key: "duration", duration: syncDuration)
	]
)
```

This keeps call-sites small, makes common payload properties reusable, and makes each record more useful. Your app still calls `log.info`, but the record now carries the context you need to understand what happened for future debugging sessions.

---

## Destinations

Broadcast includes a few destinations out of the box:

- `ConsoleLogger` writes to Apple's unified logging system.
- `SessionLogger` buffers logs in memory for the current launch.
- `MultiSessionLogger` buffers logs across launches using a [Boutique](https://github.com/mergesort/boutique) `Store`.

Destinations are composable, so one call-site can power multiple debugging workflows.

```swift
let supportLogger = SessionLogger()
let promptLogger = SessionLogger(
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
		promptLogger,
		multiSessionLogger
	]
)
```

You can also append a new `LoggingDestination` to an existing `Log`, returning a new `Log` that sends records to even more destinations without having to make global changes.

```swift
let syncLog = log.combined(with: SyncDiagnosticsDestination())

syncLog.debug(
	.diagnostic,
	"Retrying sync request",
	category: "Sync",
	payload: [
		.init(key: "attempt", value: 2),
		.init(key: "reason", value: "NetworkUnavailable")
	]
)
```

To create a custom destination, conform to `LoggingDestination` and implement `log(_:)` for each `Log.Record`.

```swift
final class UploadLoggingDestination: LoggingDestination {
	func log(_ record: Log.Record) {
		let text = record.formatted(.json)
		// Upload, save, print, enqueue, or do anything you want with the rendered record.
	}
}
```

---

## Formatting

Broadcast treats `Log.Record` as the source of truth for logs, and asks destinations to decide how logs are rendered.

```swift
let record = Log.Record(
	level: .info,
	signal: .state,
	message: "Loaded links",
	category: "Library",
	payload: [
		.linkCount(links.count)
	]
)

// We can format this record in numerous ways.
record.formatted(.default)
record.formatted(.json)
record.formatted(.canonicalLogLine)
record.formatted(.tokenOptimized)
```

The built-in formats cover the common cases:

- `.default`: Human-readable support logs.
- `.json`: Structured records for ingestion and easy inspection with JSON tools.
- `.canonicalLogLine`: A dense key-value format inspired by [Stripe's canonical log lines](https://stripe.com/blog/canonical-log-lines).
- `.tokenOptimized`: A compact logging format designed to optimize AI context windows.

Sometimes the same log record needs a different shape depending on where it's going. Support exports should be readable, JSON exports should be structured, and AI debugging logs should be compact enough to fit more history into context. When Broadcast's built-in formats are not the right shape, you can define a custom `FormatStyle` for `Log.Record`.

```swift
import Foundation

struct SupportPromptFormatStyle: Foundation.FormatStyle, Sendable {
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

extension FormatStyle where Self == SupportPromptFormatStyle {
	static var supportPrompt: Self {
		Self()
	}
}

let prompt = sessionLogger.records()
	.map({ $0.formatted(.supportPrompt) })
	.joined(separator: "\n")
```

Without runtime logs, AI coding agents can only infer behavior from source code. With Broadcast, they can read the actual sequence of actions, state changes, network decisions, metrics, and errors, then reason from the same evidence you would use to debug the issue yourself.

---

## Documentation

Broadcast includes DocC documentation in [`Sources/Broadcast/Documentation.docc`](Sources/Broadcast/Documentation.docc).

The documentation starts with the same simple mental model as this README, then goes deeper into:

- Creating and injecting a shared `Log`.
- Choosing destinations.
- Designing structured payload vocabulary.
- Exporting logs for support and AI debugging.
- Creating custom record formats.
- Testing logging behavior.

To generate the docs locally from the repository root:

```bash
swift package generate-documentation --target Broadcast
```

Use the Swift package command rather than running `xcrun docc convert` directly. The package command builds Broadcast's symbol graph before converting the DocC catalog, which is required for symbol links like ``Log`` and ``SessionLogger`` to resolve correctly.

---

## Coding Agent Plugins

Broadcast includes [Claude Code](https://claude.ai/code) and [Codex](https://developers.openai.com/codex) plugins and skills so agents can integrate the library correctly, follow the recommended logging patterns, and avoid inventing APIs that do not exist.

### Claude Code

If you have cloned the Broadcast repo locally, Claude Code can discover the plugin from the repo's marketplace metadata.

### Codex

If you have cloned the Broadcast repo locally, Codex can discover the plugin from the repo's marketplace metadata.

---

## Requirements

- iOS 18.0+
- macOS 15.0+
- Xcode 16+

---

## Installation

### Swift Package Manager

Add Broadcast to your package dependencies:

```swift
dependencies: [
	.package(url: "https://github.com/mergesort/Broadcast.git", .upToNextMajor(from: "1.0.0"))
]
```

---

## Feedback & Contribution

Broadcast is still small, but the goal is ambitious: Make logging simple and powerful so you actually use it.

- If you have a question about Broadcast, please check the DocC documentation first.
- If you still have a question, suggestion, or way to improve Broadcast, [GitHub Discussions](https://github.com/mergesort/broadcast/discussions) are a good place to start.
- If you find a bug, please report it by [creating an issue](https://github.com/mergesort/broadcast/issues).

---

### About me

Hi, I'm [Joe](http://fabisevi.ch) everywhere on the web, but especially on [Bluesky](https://bsky.app/profile/mergesort.me).

### Sponsorship

Broadcast is a labor of love to help developers build better apps, making it easier for you to understand what your software is doing and make something better for your users.

If you find Broadcast valuable I would really appreciate it if you'd consider helping [sponsor my open source work](https://github.com/sponsors/mergesort), so I can continue to work on projects like Broadcast to help developers like yourself.

---

**Now that you know what Broadcast is all about, it is time to tune in.**
