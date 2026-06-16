# Formatting Records

Broadcast treats ``Log/Record`` as the source of truth for logs, and asks destinations to format their logs. The same record can be formatted for human-readable support logs, JSON exports, canonical log lines, or a token-optimized format for agents.

## Format a record

``Log/Record`` keeps our level, timestamp, signal, category, message, and payload separate.

```swift
let record = Log.Record(
	level: .info,
	signal: .state,
	message: "Synced links",
	category: "Sync",
	payload: [
		.init(key: "linkCount", value: 10)
	]
)

let text = record.formatted(.default)
```

## Choose a built-in format

The built-in formats cover common cases.

### Default

Use `.default` for human-readable logs.

```swift
record.formatted(.default)
```

```text
[Info | State | Sync] @ 2026-06-15T12:00:00Z | Synced links | payload=[linkCount=10]
```

### JSON

Use `.json` for structured records that can be inspected with JSON tools.

```swift
let jsonLine = record.formatted(.json)
```

Join multiple records with newlines when you want JSON Lines-compatible output.

### Canonical log line

Use `.canonicalLogLine` when you want dense key-value text.

```swift
let line = record.formatted(.canonicalLogLine)
```

### Token optimized

Use `.tokenOptimized` for coding agent context windows.

```swift
let debuggingLogs = records
	.map({ $0.formatted(.tokenOptimized) })
	.joined(separator: "\n")
```

```text
t=42125 l=info s=State c=Sync m="Synced links" p.linkCount=10
```

## Configure a destination formatter

Destinations expose a ``LoggingDestination/recordFormatter``. Return a ``Log/Record/Formatter`` when a destination should always use the same format.

```swift
final class AIDebuggingLoggingDestination: LoggingDestination {
	var recordFormatter: Log.Record.Formatter {
		.tokenOptimized
	}

	func log(_ record: Log.Record) {
		let text = self.recordFormatter.format(record)
		// Store AI debugging text.
	}
}
```

## Create a custom format

When Broadcast's built-in formats are not the right shape, you can define a custom `FormatStyle` for ``Log/Record``.

```swift
import Broadcast
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

Wrap the format in ``Log/Record/Formatter`` when you want to store it on a destination.

```swift
var recordFormatter: Log.Record.Formatter {
	Log.Record.Formatter(.support)
}
```
