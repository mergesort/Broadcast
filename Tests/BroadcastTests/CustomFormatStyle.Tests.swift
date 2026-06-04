import Broadcast
import Foundation
import Testing

struct CustomFormatStyleTests {
	@Test
	func consumerCanCreateCustomPayloadFormatStyle() {
		let payload = Log.Payload(key: "priority", value: "High")

		let defaultOutput = payload.formatted(.logPayload)
		let customOutput = payload.formatted(.consumerPayload)

		#expect(defaultOutput == "priority=High")
		#expect(customOutput == "<priority>")
		#expect(customOutput != defaultOutput)
	}

	@Test
	func consumerCanCreateCustomTimestampFormatStyle() {
		let timestamp = Log.Timestamp(Date(timeIntervalSince1970: 42))

		let defaultOutput = timestamp.formatted(.default)
		let customOutput = timestamp.formatted(.consumerTimestamp)

		#expect(defaultOutput == "1970-01-01T00:00:42Z")
		#expect(customOutput == "seconds=42")
		#expect(customOutput != defaultOutput)
	}

	@Test
	func consumerCanCreateCustomRecordFormatStyle() {
		let record = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
			level: .info,
			signal: .state,
			message: "Loaded reminders",
			category: "Reminders",
			payload: [.init(key: "count", value: 3)]
		)

		let defaultOutput = record.formatted(.default)
		let customOutput = record.formatted(.consumerRecord)

		#expect(defaultOutput == "[Info | State | Reminders] @ 1970-01-01T00:00:42Z | Loaded reminders | payload=[count=3]")
		#expect(customOutput == "State/Reminders/Loaded reminders/count=3")
		#expect(customOutput != defaultOutput)
	}

	@Test
	func consumerCanUseCustomRecordFormatterWithDestination() {
		let destination = ConsumerRecordFormatLoggingDestination()
		let log = Log(destinations: [destination])

		log.info(
			.state,
			"Loaded reminders",
			category: "Reminders",
			payload: [.init(key: "count", value: 3)]
		)

		#expect(destination.infoLogs == ["State/Reminders/Loaded reminders/count=3"])
	}

	@Test
	func consumerCanCombineCustomFormattersEndToEnd() {
		let dateProvider = Log.DateProvider { Date(timeIntervalSince1970: 42) }
		let destination = ConsumerEndToEndLoggingDestination(dateProvider: dateProvider)
		let log = Log(destinations: [destination])
		let record = Log.Record(
			timestamp: Log.Timestamp(dateProvider.date),
			level: .info,
			signal: .metric,
			message: "Measured reminder sync",
			category: "Sync",
			payload: [
				.init(key: "duration", duration: 1.25),
				.init(key: "count", value: 3)
			]
		)

		log.info(.metric, record.message, category: "Sync", payload: record.payload)

		let defaultRecordOutput = record.formatted(.default)
		let customRecordOutput = record.formatted(.consumerEndToEndRecord)
		let defaultTimestampOutput = Log.Timestamp(dateProvider.date).formatted(.default)
		let customTimestampOutput = Log.Timestamp(dateProvider.date).formatted(.consumerTimestamp)

		#expect(defaultRecordOutput == "[Info | Metric | Sync] @ 1970-01-01T00:00:42Z | Measured reminder sync | payload=[duration=1.25s, count=3]")
		#expect(customRecordOutput == "Metric/Sync: Measured reminder sync {<duration>, <count>}")
		#expect(defaultTimestampOutput == "1970-01-01T00:00:42Z")
		#expect(customTimestampOutput == "seconds=42")
		#expect(customRecordOutput != defaultRecordOutput)
		#expect(customTimestampOutput != defaultTimestampOutput)
		#expect(destination.infoLogs == ["seconds=42 :: Metric/Sync: Measured reminder sync {<duration>, <count>}"])
	}
}

// MARK: ConsumerPayloadFormatStyle

private struct ConsumerPayloadFormatStyle: FormatStyle, Sendable {
	func format(_ value: Log.Payload) -> String {
		"<\(value.key)>"
	}
}

private extension FormatStyle where Self == ConsumerPayloadFormatStyle {
	static var consumerPayload: Self {
		Self()
	}
}

// MARK: ConsumerTimestampFormatStyle

private struct ConsumerTimestampFormatStyle: FormatStyle, Sendable {
	func format(_ value: Log.Timestamp) -> String {
		"seconds=\(Int(value.date.timeIntervalSince1970))"
	}
}

private extension FormatStyle where Self == ConsumerTimestampFormatStyle {
	static var consumerTimestamp: Self {
		Self()
	}
}

// MARK: ConsumerRecordFormatStyle

private struct ConsumerRecordFormatStyle: FormatStyle, Sendable {
	func format(_ value: Log.Record) -> String {
		[
			value.signal?.identifier,
			value.category?.identifier,
			value.message.isEmpty ? nil : value.message,
			value.payload.map({ $0.formatted(.logPayload) }).joined(separator: ",")
		]
		.compactMap({ $0 })
		.filter({ !$0.isEmpty })
		.joined(separator: "/")
	}
}

private extension FormatStyle where Self == ConsumerRecordFormatStyle {
	static var consumerRecord: Self {
		Self()
	}
}

// MARK: ConsumerEndToEndRecordFormatStyle

private struct ConsumerEndToEndRecordFormatStyle: FormatStyle, Sendable {
	func format(_ value: Log.Record) -> String {
		let payload = value.payload
			.map({ $0.formatted(.consumerPayload) })
			.joined(separator: ", ")
		var text = [
			value.signal?.identifier,
			value.category?.identifier
		]
		.compactMap({ $0 })
		.joined(separator: "/")

		if !text.isEmpty {
			text += ": "
		}

		return "\(text)\(value.message) {\(payload)}"
	}
}

private extension FormatStyle where Self == ConsumerEndToEndRecordFormatStyle {
	static var consumerEndToEndRecord: Self {
		Self()
	}
}

// MARK: ConsumerRecordFormatLoggingDestination

private final class ConsumerRecordFormatLoggingDestination: LoggingDestination {
	private(set) var infoLogs: [String] = []

	var recordFormatter: Log.Record.Formatter {
		Log.Record.Formatter(.consumerRecord)
	}

	func log(_ record: Log.Record) {
		if case .info = record.level {
			self.infoLogs.append(self.recordFormatter.format(record))
		}
	}
}

// MARK: ConsumerEndToEndLoggingDestination

private final class ConsumerEndToEndLoggingDestination: LoggingDestination {
	let dateProvider: Log.DateProvider
	private(set) var infoLogs: [String] = []

	init(dateProvider: Log.DateProvider) {
		self.dateProvider = dateProvider
	}

	var recordFormatter: Log.Record.Formatter {
		Log.Record.Formatter(.consumerEndToEndRecord)
	}

	func log(_ record: Log.Record) {
		let timestamp = Log.Timestamp(self.dateProvider.date).formatted(.consumerTimestamp)

		if case .info = record.level {
			self.infoLogs.append("\(timestamp) :: \(self.recordFormatter.format(record))")
		}
	}
}
