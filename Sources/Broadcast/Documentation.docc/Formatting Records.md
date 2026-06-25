# Formatting Records

Broadcast treats ``Log/Record`` as the source of truth for logs, and asks destinations to format their logs.

## Format a record

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

``Log/Record`` keeps our level, timestamp, signal, category, message, and payload separate so the same record can be formatted in different ways.

## Built In Formats

The built-in formats cover common cases.

### Default

`.default`: A human-readable log format.

```text
[Info | State | Sync] @ 1970-01-01T00:00:42Z | Synced links | payload=[linkCount=10, tagCount=5]
```

### JSON

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

### Canonical log line

`.canonicalLogLine`: A dense key-value text inspired by [Stripe's canonical log lines](https://stripe.com/blog/canonical-log-lines).

```text
[1970-01-01T00:00:42Z] canonical-log-line level=info signal=State category=Sync message="Synced links" linkCount=10 tagCount=5
```

### Token optimized

`.tokenOptimized`: A compact log format designed to optimize AI context windows.

```text
t=42000 l=info s=State c=Sync m="Synced links" p.linkCount=10 p.tagCount=5
```

## Creating a custom format

If Broadcast's built-in formats aren't the right fit for your needs, you can define a custom `FormatStyle`:

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
```

You can then format your records with different shapes on a per-export basis:

```swift
let records = sessionLogger.records()

let supportLogs = records
	.map({ $0.formatted(.support) })
	.joined(separator: "\n")

let tokenOptimizedLogs = records
	.map({ $0.formatted(.tokenOptimized) })
	.joined(separator: "\n")

let jsonLogs = records
	.map({ $0.formatted(.json) })
	.joined(separator: "\n")
```

## Configure a destination formatter

Destinations expose a ``LoggingDestination/recordFormatter``. Wrap a format in ``Log/Record/Formatter`` when you want to store it on a destination.

```swift
var recordFormatter: Log.Record.Formatter {
	Log.Record.Formatter(.support)
}
```
