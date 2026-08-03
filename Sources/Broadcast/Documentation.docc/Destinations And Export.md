# Destinations and Export

Destinations are what make Broadcast composable. One call to `log.info` can write to the console, keep an in-memory support log, persist records across launches, or feed a custom destination for uploads, analytics, or AI debugging. Your app invokes one simple API and each destination handles the records and formatting.

## Built-In Destinations

Broadcast includes a few destinations out of the box:

- ``ConsoleLogger`` writes to Apple's unified logging system on Apple platforms.
- ``SessionLogger`` buffers logs in memory for the current launch.
- ``MultiSessionLogger`` persists logs across launches when the `MultiSessionLogging` package trait is enabled. It currently uses a [Boutique](https://github.com/mergesort/boutique) `Store` on Apple platforms.

On Linux, enable the `SwiftLogging` package trait and use ``SwiftLogDestination``
for process output instead of ``ConsoleLogger``.

## Forward Records to swift-log

Broadcast can forward records to [apple/swift-log](https://github.com/apple/swift-log) when the package is built with the `SwiftLogging` trait. Use this when Broadcast should stay as your app or server's call-site API, but records should also flow into the process's configured swift-log backend.

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

`SwiftLogDestination` maps Broadcast's `debug`, `info`, `warn`, `error`, and `fault` levels to swift-log's `debug`, `info`, `warning`, `error`, and `critical` levels. It forwards Broadcast's record identifier, timestamp, signal, and category with `broadcast.*` metadata keys, and payload values with `payload.*` metadata keys.

## Use Multiple Destinations

Start by creating the destinations your app or package needs, then attach them to the same shared ``Log``. In an app or app-specific package, this is usually the same global `let log` you call from the rest of your code.

```swift
import Broadcast
import Boutique

let supportLogger = SessionLogger()

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

Now every `log.info`, `log.debug`, or `log.error` call will write to each destination.

## Export Current-Session Logs

``SessionLogger`` buffers logs in memory for the current launch.

```swift
let supportRecords = supportLogger.records()
let supportLogs = supportLogger.logs()
```

Use `logs()` when you want readable text for support screens or bug report attachments. Use `records()` when you want the original ``Log/Record`` values so you can export them in a different format, such as `.tokenOptimized` for AI debugging.

## Persist Logs Across Launches

``MultiSessionLogger`` buffers logs across launches using a Boutique `Store`.
The `MultiSessionLogging` package trait enables this API and is part of Broadcast's
default traits, so existing Apple integrations receive it automatically.

```swift
import Broadcast
import Boutique

let logStore = try await Store<Log.Record>(
	storage: SQLiteStorageEngine.default(appendingPath: "Logs")
)

let multiSessionLogger = MultiSessionLogger(store: logStore)

let log = Log(destinations: [multiSessionLogger])
```

The host app owns the store configuration, so it can configure the right storage location for its needs. Use multi-session logs when there is useful evidence that problems persist across multiple app launches.

## Compose Destination Sets

Use `combined(with:)` to append a ``LoggingDestination`` to an existing ``Log``. This will give one part of your app an extra destination without changing your global logger.

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

In an app like [Plinky](https://plinky.app) I use this for package-specific logging. The Analytics package starts with Plinky's app-wide logger, combines it with an `AnalyticsLogger`, and keeps calling `log.info` like every other package. Each analytics record still goes to Plinky's normal logging destinations, but it also goes to the analytics-specific destination.

```swift
let log = Log.plinky.combined(with: AnalyticsLogger())
```

## Create a Custom Destination

Create a custom destination by conforming to ``LoggingDestination`` and implementing ``LoggingDestination/log(_:)`` for each ``Log/Record``.

Custom destinations are useful for analytics, remote uploads, test capture, and app-specific diagnostics.

```swift
import Broadcast
import Foundation

final class UploadLoggingDestination: LoggingDestination {
	private let upload: @Sendable (Data) async throws -> Void

	init(upload: @escaping @Sendable (Data) async throws -> Void) {
		self.upload = upload
	}

	func log(_ record: Log.Record) {
		let data = Data(record.formatted(.json).utf8)
		let upload = self.upload

		Task {
			do {
				try await upload(data)
			} catch {
				// Decide how your app should handle failed log uploads.
			}
		}
	}
}
```

Once you have a destination, add it to your shared ``Log`` or compose it into a narrower logger for the part of your app that needs remote diagnostics.

```swift
let uploadLogger = UploadLoggingDestination { data in
	try await logUploadClient.upload(data)
}

let remoteLog = log.combined(with: uploadLogger)
```

Since ``LoggingDestination/log(_:)`` is synchronous, hand asynchronous work off to your own queue, task, actor, or upload client.

Override ``LoggingDestination/recordFormatter`` when a destination should always use a specific format.

```swift
final class AIDebuggingLoggingDestination: LoggingDestination {
	var recordFormatter: Log.Record.Formatter {
		.tokenOptimized
	}

	func log(_ record: Log.Record) {
		let text = self.recordFormatter.format(record)
		// Append text to an AI debugging buffer.
	}
}
```
