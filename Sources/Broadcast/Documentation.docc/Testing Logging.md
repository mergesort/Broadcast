# Testing Your Logging

Broadcast is built with testability in mind. You can test records, fields, formatters, destinations, and any other part of Broadcast that is exposed to developers.

## Use A Buffered Destination

``SessionLogger`` keeps emitted records in memory, making it useful for tests that need to inspect what your app logged.

```swift
let logger = SessionLogger(
	dateProvider: Log.DateProvider {
		Date(timeIntervalSince1970: 0)
	}
)

let log = Log(destinations: [logger])

log.info(
	.state,
	"Synced links",
	category: "Sync",
	payload: [
		.init(key: "linkCount", value: 10)
	]
)

let records = logger.records()
```

## Test Records Rather Than Outputs

When you care about app behavior, prefer ``BufferedLoggingDestination/records()`` and assert against ``Log/Record`` fields instead of rendered text.

```swift
let record = try #require(logger.records().first)

#expect(record.level == .info)
#expect(record.signal == .state)
#expect(record.category?.identifier == "Sync")
#expect(record.message == "Synced links")
#expect(record.payload.map(\.key) == ["linkCount"])
```

Testing individual properties will keep your tests resilient, even when your output formatting changes.

## Use Fixed Dates For Formatted Logs

``Log/DateProvider`` supplies dates for buffered log entries. Apps usually use ``Log/DateProvider/default``, but tests should inject a fixed provider to make formatted timestamps deterministic.

Use a fixed ``Log/DateProvider`` whenever formatted timestamps are part of the assertion.

```swift
let logger = SessionLogger(
	dateProvider: Log.DateProvider {
		Date(timeIntervalSince1970: 0)
	}
)

logger.info("Created reminder")

#expect(logger.logs() == "[Info] @ 1970-01-01T00:00:00Z | Created reminder")
```

## Testing Custom Destinations

Use a custom destination when a test needs to capture records for the purposes of verification.

```swift
final class CapturingLoggingDestination: LoggingDestination {
	private(set) var records: [Log.Record] = []
	private(set) var debugLogs: [String] = []
	private(set) var infoLogs: [String] = []
	private(set) var warnLogs: [String] = []
	private(set) var errorLogs: [String] = []
	private(set) var faultLogs: [String] = []

	func log(_ record: Log.Record) {
		self.records.append(record)
		let text = self.recordFormatter.format(record)

		switch record.level {
		case .debug: self.debugLogs.append(text)
		case .info: self.infoLogs.append(text)
		case .warn: self.warnLogs.append(text)
		case .error: self.errorLogs.append(text)
		case .fault: self.faultLogs.append(text)
		}
	}
}
```

This will allow you to assert the destination received the records you expect.

```swift
let firstDestination = CapturingLoggingDestination()
let secondDestination = CapturingLoggingDestination()
let log = Log(destinations: [firstDestination, secondDestination])

log.info("Synced", 10, "links")

#expect(firstDestination.records.map(\.message) == ["Synced, 10, links"])
#expect(secondDestination.records.map(\.message) == ["Synced, 10, links"])
#expect(firstDestination.infoLogs.count == 1)
```

## Testing FormatStyles

You can test a custom `FormatStyle` by formatting a known value and asserting the custom output.

```swift
import Foundation

struct SupportFormatStyle: FormatStyle, Sendable {
	func format(_ value: Log.Record) -> String {
		[
			value.signal?.identifier,
			value.category?.identifier,
			value.message
		]
		.compactMap({ $0 })
		.joined(separator: "/")
	}
}

extension FormatStyle where Self == SupportFormatStyle {
	static var support: Self {
		Self()
	}
}

let record = Log.Record(
	timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
	level: .info,
	signal: .state,
	message: "Synced links",
	category: "Sync",
	payload: [
		.init(key: "linkCount", value: 10)
	]
)

let customOutput = record.formatted(.support)

#expect(customOutput == "State/Sync/Synced links")
```

When a destination overrides ``LoggingDestination/recordFormatter``, assert the destination received the formatted text you expect.

```swift
final class SupportLoggingDestination: LoggingDestination {
	private(set) var infoLogs: [String] = []

	var recordFormatter: Log.Record.Formatter {
		Log.Record.Formatter(.support)
	}

	func log(_ record: Log.Record) {
		if case .info = record.level {
			self.infoLogs.append(self.recordFormatter.format(record))
		}
	}
}

let destination = SupportLoggingDestination()
let log = Log(destinations: [destination])

log.info(
	.state,
	"Synced links",
	category: "Sync",
	payload: [
		.init(key: "linkCount", value: 10)
	]
)

#expect(destination.infoLogs == ["State/Sync/Synced links"])
```

The unit test for our `FormatStyle` proves the formatter's shape, and the destination test proves that your logger is using the correct `FormatStyle`.

## Only Test Text When Necessary

Tests should rarely assert their exact formatted output. Only test logged strings directly when the text itself is the thing you are promising to return.

Broadcast's test do this for ``SessionLogger`` because the string returned from ``SessionLogger/logs(count:)`` is part of the API, but if you're testing a record or formatter or destination, you should prefer testing record fields directly. 

```swift
let logger = SessionLogger(
	dateProvider: Log.DateProvider {
		Date(timeIntervalSince1970: 0)
	}
)

logger.info("Created reminder")

#expect(logger.logs() == "[Info] @ 1970-01-01T00:00:00Z | Created reminder")
```