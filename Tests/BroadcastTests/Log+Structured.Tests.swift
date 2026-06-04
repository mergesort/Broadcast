@testable import Broadcast
import Foundation
import Testing

struct StructuredLogTests {
	@Test
	func formatsRecordWithDefaultBroadcastFormatStyle() {
		let record = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 0)),
			level: .info,
			signal: .state,
			message: "Loaded reminders",
			category: "Reminders",
			payload: [
				.init(key: "result", value: "Success"),
				.init(key: "reminderCount", value: 3)
			]
		)

		#expect(record.formatted(.default) == "[Info | State | Reminders] @ 1970-01-01T00:00:00Z | Loaded reminders | payload=[result=Success, reminderCount=3]")
	}

	@Test
	func formatsRecordWithCustomFormatStyle() {
		let record = Log.Record(
			level: .info,
			signal: .state,
			message: "Loaded reminders",
			category: "Reminders",
			payload: [
				.init(key: "result", value: "Success")
			]
		)

		#expect(record.formatted(.compactRecord) == "State/Reminders: Loaded reminders (result=Success)")
	}

	@Test
	func formatsStructuredLogsWithCustomDestinationRecordFormatStyle() {
		let destination = CustomRecordFormatLoggingDestination()
		let log = Log(destinations: [destination])

		log.info(
			.state,
			"Loaded reminders",
			category: "Reminders",
			payload: [
				.init(key: "result", value: "Success")
			]
		)

		#expect(destination.infoLogs == ["State/Reminders: Loaded reminders (result=Success)"])
	}

	@Test
	func formatsStructuredLogsWithClosureBasedRecordFormatStyle() {
		let style = Log.Record.Formatter { record in
			[
				record.category?.identifier,
				record.message
			]
			.compactMap({ $0 })
			.joined(separator: ": ")
		}

		let record = Log.Record(
			level: .info,
			signal: .state,
			message: "Loaded reminders",
			category: "Reminders"
		)

		#expect(style.format(record) == "Reminders: Loaded reminders")
	}

	@Test
	func createsRecordWithDefaultTimestamp() {
		let before = Date()
		let record = Log.Record(
			level: .info,
			signal: .state,
			message: "Loaded reminders",
			category: "Reminders"
		)
		let after = Date()

		#expect(record.timestamp.date >= before)
		#expect(record.timestamp.date <= after)
	}

	@Test
	func createsRecordWithExplicitTimestamp() {
		let timestamp = Log.Timestamp(Date(timeIntervalSince1970: 42))
		let record = Log.Record(
			timestamp: timestamp,
			level: .info,
			signal: .state,
			message: "Loaded reminders",
			category: "Reminders"
		)

		#expect(record.timestamp == timestamp)
	}

	@Test
	func createsRecordWithDefaultID() {
		let firstRecord = Log.Record(
			level: .info,
			signal: .state,
			message: "Loaded reminders",
			category: "Reminders"
		)
		let secondRecord = Log.Record(
			level: .info,
			signal: .state,
			message: "Loaded reminders",
			category: "Reminders"
		)

		#expect(firstRecord.id != secondRecord.id)
	}

	@Test
	func forwardsStructuredLogsToDestinationsBeforeFormatting() throws {
		let destination = CapturingStructuredLoggingDestination()
		let log = Log(destinations: [destination])

		log.info(
			.state,
			"Loaded reminders",
			category: "Reminders",
			payload: [
				.init(key: "result", value: "Success")
			]
		)

		let record = try #require(destination.receivedRecords.first)

		#expect(destination.receivedRecords.count == 1)
		#expect(record.level == .info)
		#expect(record.signal == .state)
		#expect(record.message == "Loaded reminders")
		#expect(record.category == "Reminders")
		#expect(record.payload == [.init(key: "result", value: "Success")])
		#expect(destination.infoLogs.isEmpty)
	}

	@Test
	func formatsPayloadWithDefaultPayloadFormatStyle() throws {
		let id = try #require(UUID(uuidString: "00000000-0000-4000-8000-000000000001"))

		#expect(Log.Payload(key: "id", value: id).formatted(.logPayload) == "id=00000000-0000-4000-8000-000000000001")
		#expect(Log.Payload.Value.bool(true).formatted(.logPayloadValue) == "true")
	}

	@Test
	func formatsStructuredLogsWithPayload() {
		let destination = CapturingLoggingDestination()
		let log = Log(destinations: [destination])

		log.info(
			.action,
			"Updated reminder priority",
			category: "Reminders",
			payload: [
				.init(key: "result", value: "Success"),
				.init(key: "title", value: "Buy milk"),
				.init(key: "priority", value: "High")
			]
		)

		expectStructuredLog(
			destination.infoLogs.first,
			prefix: "[Info | Action | Reminders] @ ",
			suffix: " | Updated reminder priority | payload=[result=Success, title=Buy milk, priority=High]"
		)
		#expect(destination.infoLogs.count == 1)
	}

	@Test
	func omitsPayloadSectionWhenPayloadIsEmpty() {
		let destination = CapturingLoggingDestination()
		let log = Log(destinations: [destination])

		log.info(.action, "Started reminder sync", category: "Sync")

		expectStructuredLog(
			destination.infoLogs.first,
			prefix: "[Info | Action | Sync] @ ",
			suffix: " | Started reminder sync"
		)
		#expect(destination.infoLogs.count == 1)
	}

	@Test
	func preservesPayloadOrder() {
		let destination = CapturingLoggingDestination()
		let log = Log(destinations: [destination])

		log.info(
			.action,
			"Created reminder",
			category: "Reminders",
			payload: [
				.init(key: "title", value: "Buy milk"),
				.init(key: "priority", value: "High"),
				.init(key: "dueDate", value: "Tomorrow")
			]
		)

		expectStructuredLog(
			destination.infoLogs.first,
			prefix: "[Info | Action | Reminders] @ ",
			suffix: " | Created reminder | payload=[title=Buy milk, priority=High, dueDate=Tomorrow]"
		)
		#expect(destination.infoLogs.count == 1)
	}

	@Test
	func writesStructuredLogsToEveryLevel() {
		let destination = CapturingLoggingDestination()
		let log = Log(destinations: [destination])

		log.debug(.state, "Collected reminder diagnostics", category: "Reminders")
		log.info(.action, "Created reminder", category: "Reminders")
		log.warn(.event, "Reached notification retry threshold", category: "Notifications")
		log.error(.action, "Failed reminder sync", category: "Sync")
		log.fault(.diagnostic, "Detected reminder store corruption", category: "Persistence")

		expectStructuredLog(destination.debugLogs.first, prefix: "[Debug | State | Reminders] @ ", suffix: " | Collected reminder diagnostics")
		expectStructuredLog(destination.infoLogs.first, prefix: "[Info | Action | Reminders] @ ", suffix: " | Created reminder")
		expectStructuredLog(destination.warnLogs.first, prefix: "[Warn | Event | Notifications] @ ", suffix: " | Reached notification retry threshold")
		expectStructuredLog(destination.errorLogs.first, prefix: "[Error | Action | Sync] @ ", suffix: " | Failed reminder sync")
		expectStructuredLog(destination.faultLogs.first, prefix: "[Fault | Diagnostic | Persistence] @ ", suffix: " | Detected reminder store corruption")
		#expect(destination.debugLogs.count == 1)
		#expect(destination.infoLogs.count == 1)
		#expect(destination.warnLogs.count == 1)
		#expect(destination.errorLogs.count == 1)
		#expect(destination.faultLogs.count == 1)
	}

	@Test
	func exposesDefaultSignals() {
		#expect(Log.Signal.action.identifier == "Action")
		#expect(Log.Signal.state.identifier == "State")
		#expect(Log.Signal.event.identifier == "Event")
		#expect(Log.Signal.metric.identifier == "Metric")
		#expect(Log.Signal.diagnostic.identifier == "Diagnostic")
	}

	@Test
	func storesTypedPayloadValues() throws {
		let id = try #require(UUID(uuidString: "00000000-0000-4000-8000-000000000001"))
		let url = try #require(URL(string: "https://example.com/reminders/1"))
		let date = try Date.ISO8601FormatStyle().parse("2026-05-23T12:00:00Z")
		let error = NSError(domain: "BroadcastTests", code: 42, userInfo: [NSLocalizedDescriptionKey: "Something failed"])

		#expect(Log.Payload(key: "string", value: "hello").value == .string("hello"))
		#expect(Log.Payload(key: "optionalString", value: nil as String?).value == .string(nil))
		#expect(Log.Payload(key: "bool", value: true).value == .bool(true))
		#expect(Log.Payload(key: "int", value: 42).value == .int(42))
		#expect(Log.Payload(key: "uuid", value: id).value == .uuid(id))
		#expect(Log.Payload(key: "optionalUUID", value: nil as UUID?).value == .uuid(nil))
		#expect(Log.Payload(key: "url", value: url).value == .url(url))
		#expect(Log.Payload(key: "optionalURL", value: nil as URL?).value == .url(nil))
		#expect(Log.Payload(key: "date", value: date).value == .date(date))
		#expect(Log.Payload(key: "optionalDate", value: nil as Date?).value == .date(nil))
		#expect(Log.Payload(key: "error", value: error).value == .error("Something failed"))
		#expect(Log.Payload(key: "duration", duration: 1.234).value == .duration(1.234))
	}

	@Test
	func formatsTypedPayloadValues() throws {
		let destination = CapturingLoggingDestination()
		let log = Log(destinations: [destination])
		let id = try #require(UUID(uuidString: "00000000-0000-4000-8000-000000000001"))
		let url = try #require(URL(string: "https://example.com/reminders/1"))
		let date = try Date.ISO8601FormatStyle().parse("2026-05-23T12:00:00Z")
		let error = NSError(domain: "BroadcastTests", code: 42, userInfo: [NSLocalizedDescriptionKey: "Something failed"])

		log.info(
			.metric,
			"Measured reminder payload formatting",
			category: "Reminders",
			payload: [
				.init(key: "string", value: "hello"),
				.init(key: "optionalString", value: nil as String?),
				.init(key: "bool", value: true),
				.init(key: "int", value: 42),
				.init(key: "uuid", value: id),
				.init(key: "optionalUUID", value: nil as UUID?),
				.init(key: "url", value: url),
				.init(key: "optionalURL", value: nil as URL?),
				.init(key: "date", value: date),
				.init(key: "optionalDate", value: nil as Date?),
				.init(key: "error", value: error),
				.init(key: "duration", duration: 1.234)
			]
		)

		expectStructuredLog(
			destination.infoLogs.first,
			prefix: "[Info | Metric | Reminders] @ ",
			suffix: " | Measured reminder payload formatting | payload=[string=hello, optionalString=nil, bool=true, int=42, uuid=00000000-0000-4000-8000-000000000001, optionalUUID=nil, url=https://example.com/reminders/1, optionalURL=nil, date=\(date.formatted(.iso8601)), optionalDate=nil, error=Something failed, duration=1.23s]"
		)
		#expect(destination.infoLogs.count == 1)
	}

	@Test
	func formatsDatePayloadWithDefaultTimestampFormat() {
		let destination = CapturingLoggingDestination()
		let log = Log(destinations: [destination])
		let date = Date(timeIntervalSince1970: 0)

		log.info(
			.metric,
			"Measured reminder timestamp",
			category: "Reminders",
			payload: [
				.init(key: "timestamp", value: date)
			]
		)

		expectStructuredLog(
			destination.infoLogs.first,
			prefix: "[Info | Metric | Reminders] @ ",
			suffix: " | Measured reminder timestamp | payload=[timestamp=1970-01-01T00:00:00Z]"
		)
		#expect(destination.infoLogs.count == 1)
	}

	@Test
	func preservesCustomSignalAndCategoryIdentifiers() {
		let destination = CapturingLoggingDestination()
		let log = Log(destinations: [destination])

		let signal = Log.Signal(identifier: "Audit")
		let category = Log.Category(identifier: "Reminders")

		log.info(signal, "Verified reminder access", category: category, payload: [.init(key: "actor", value: "system")])

		expectStructuredLog(
			destination.infoLogs.first,
			prefix: "[Info | Audit | Reminders] @ ",
			suffix: " | Verified reminder access | payload=[actor=system]"
		)
		#expect(destination.infoLogs.count == 1)
	}

	@Test
	func formatsMetricSignal() {
		let destination = CapturingLoggingDestination()
		let log = Log(destinations: [destination])

		log.info(.metric, "Measured reminder sync duration", category: "Sync", payload: [.init(key: "duration", value: "0.50s")])

		expectStructuredLog(
			destination.infoLogs.first,
			prefix: "[Info | Metric | Sync] @ ",
			suffix: " | Measured reminder sync duration | payload=[duration=0.50s]"
		)
		#expect(destination.infoLogs.count == 1)
	}
}

// MARK: Expectations

private func expectStructuredLog(_ actual: String?, prefix: String, suffix: String) {
	#expect(actual?.hasPrefix(prefix) == true)
	#expect(actual?.hasSuffix(suffix) == true)
}

// MARK: CapturingStructuredLoggingDestination

private final class CapturingStructuredLoggingDestination: LoggingDestination {
	private(set) var infoLogs: [String] = []
	private(set) var receivedRecords: [Log.Record] = []

	func log(_ record: Log.Record) {
		if case .info = record.level {
			self.receivedRecords.append(record)
		}
	}
}

// MARK: CustomRecordFormatLoggingDestination

private final class CustomRecordFormatLoggingDestination: LoggingDestination {
	private(set) var infoLogs: [String] = []

	var recordFormatter: Log.Record.Formatter {
		Log.Record.Formatter(.compactRecord)
	}

	func log(_ record: Log.Record) {
		if case .info = record.level {
			self.infoLogs.append(self.recordFormatter.format(record))
		}
	}
}

// MARK: CompactRecordFormatStyle

private struct CompactRecordFormatStyle: FormatStyle, Sendable {
	func format(_ value: Log.Record) -> String {
		var text = [
			value.signal?.identifier,
			value.category?.identifier
		]
		.compactMap({ $0 })
		.joined(separator: "/")

		if !text.isEmpty {
			text += ": "
		}

		text += value.message

		if !value.payload.isEmpty {
			text += " (\(value.payload.map({ $0.formatted(.logPayload) }).joined(separator: ", ")))"
		}

		return text
	}
}

private extension FormatStyle where Self == CompactRecordFormatStyle {
	static var compactRecord: Self {
		Self()
	}
}
