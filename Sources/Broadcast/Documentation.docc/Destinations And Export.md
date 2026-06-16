# Destinations and Export

Destinations are what make Broadcast composable.

One call-site can write to multiple places. A record can go to Xcode, a support log, a persistent store, or a custom destination you build.

## Use multiple destinations

Start by creating the destinations your app needs, then attach them to the same ``Log``.

```swift
import Broadcast
import Boutique

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

Now every `log.info`, `log.debug`, or `log.error` call writes to each destination.

## Export current-session logs

``SessionLogger`` buffers logs in memory for the current launch.

```swift
let supportLogs = supportLogger.logs()
let supportRecords = supportLogger.records()
```

Use it for support screens, bug report attachments, and tests.

## Persist logs across launches

``MultiSessionLogger`` buffers logs across launches using a Boutique `Store`.

```swift
import Broadcast
import Boutique

let logStore = try await Store<Log.Record>(
	storage: SQLiteStorageEngine.default(appendingPath: "Logs")
)

let multiSessionLogger = MultiSessionLogger(store: logStore)

let log = Log(
	destinations: [
		ConsoleLogger(subsystem: "com.example.app", category: "logs"),
		multiSessionLogger
	]
)
```

The host app owns the store configuration, so it can choose the right app group, storage location, and retention policy.

Use multi-session logs when the useful evidence may have happened before the current launch.

## Compose destination sets

Use `combined(with:)` to append a ``LoggingDestination`` to an existing ``Log`` without making global changes.

```swift
let syncLog = log.combined(with: SyncDiagnosticsDestination())

syncLog.info(
	.action,
	"Started sync",
	category: "Sync",
	payload: [
		.init(key: "reason", value: "AppLaunch")
	]
)
```

That gives the sync system its own extra destination while the rest of your app keeps using the shared logger.

## Build a custom destination

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

The `upload` closure can be whatever networking abstraction your app already uses.

Because ``LoggingDestination/log(_:)`` is synchronous, hand asynchronous work off to your own queue, task, actor, or upload client. In a production app you would usually batch records and retry failed uploads.

Override ``LoggingDestination/recordFormatter`` when a destination should use a specific format.

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

## Export for support or AI

Buffered destinations keep records, so export can happen in the format that matches the task.

```swift
let supportText = supportLogger.logs()

let debuggingText = supportLogger.records()
	.map({ $0.formatted(.tokenOptimized) })
	.joined(separator: "\n")
```

Support logs should be readable by a person. AI debugging logs should be compact enough to include a lot of history. Broadcast lets both come from the same records.
