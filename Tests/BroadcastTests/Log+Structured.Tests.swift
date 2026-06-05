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
	func formatsRecordWithCanonicalLogLineFormatStyle() {
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

		#expect(record.formatted(.canonicalLogLine) == "[1970-01-01T00:00:00Z] canonical-log-line level=info signal=State category=Reminders message=\"Loaded reminders\" result=Success reminderCount=3")
	}

	@Test
	func formatsRecordWithJSONFormatStyle() throws {
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

		let json = try parsedJSONRecord(record.formatted(.json))
		let payload = try parsedPayload(from: json)

		#expect(json["timestamp"] as? String == "1970-01-01T00:00:00Z")
		#expect(json["level"] as? String == "info")
		#expect(json["signal"] as? String == "State")
		#expect(json["category"] as? String == "Reminders")
		#expect(json["message"] as? String == "Loaded reminders")
		#expect(payload["result"] as? String == "Success")
		#expect((payload["reminderCount"] as? NSNumber)?.intValue == 3)
	}

	@Test
	func formatsJSONWithTypedPayloadValues() throws {
		let id = try #require(UUID(uuidString: "00000000-0000-4000-8000-000000000001"))
		let url = try #require(URL(string: "https://example.com/reminders/1"))
		let date = try Date.ISO8601FormatStyle().parse("2026-05-23T12:00:00Z")
		let error = NSError(domain: "BroadcastTests", code: 42, userInfo: [NSLocalizedDescriptionKey: "Something failed"])
		let record = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
			level: .error,
			signal: .diagnostic,
			message: "Failed reminder sync",
			category: "Sync",
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
				.init(key: "duration", duration: 1.25)
			]
		)

		let output = record.formatted(.json)
		let json = try parsedJSONRecord(output)
		let payload = try parsedPayload(from: json)

		#expect(json["timestamp"] as? String == "1970-01-01T00:00:42Z")
		#expect(json["level"] as? String == "error")
		#expect(json["signal"] as? String == "Diagnostic")
		#expect(json["category"] as? String == "Sync")
		#expect(json["message"] as? String == "Failed reminder sync")
		#expect(payload["string"] as? String == "hello")
		#expect(payload["optionalString"] is NSNull)
		#expect((payload["bool"] as? NSNumber)?.boolValue == true)
		#expect((payload["int"] as? NSNumber)?.intValue == 42)
		#expect(payload["uuid"] as? String == "00000000-0000-4000-8000-000000000001")
		#expect(payload["optionalUUID"] is NSNull)
		#expect(payload["url"] as? String == "https://example.com/reminders/1")
		#expect(payload["optionalURL"] is NSNull)
		#expect(payload["date"] as? String == "2026-05-23T12:00:00Z")
		#expect(payload["optionalDate"] is NSNull)
		#expect(payload["error"] as? String == "Something failed")
		#expect((payload["duration"] as? NSNumber)?.doubleValue == 1.25)
		#expect(output.contains("https://example.com/reminders/1"))
	}

	@Test
	func formatsJSONWithEscapedStrings() throws {
		let record = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
			level: .error,
			signal: .diagnostic,
			message: "Failed \"nightly\"\nsync",
			category: "Background\\Sync",
			payload: [
				.init(key: "error message", value: "Path C:\\Logs was \"missing\"")
			]
		)

		let json = try parsedJSONRecord(record.formatted(.json))
		let payload = try parsedPayload(from: json)

		#expect(json["timestamp"] as? String == "1970-01-01T00:00:42Z")
		#expect(json["level"] as? String == "error")
		#expect(json["signal"] as? String == "Diagnostic")
		#expect(json["category"] as? String == "Background\\Sync")
		#expect(json["message"] as? String == "Failed \"nightly\"\nsync")
		#expect(payload["error message"] as? String == "Path C:\\Logs was \"missing\"")
	}

	@Test
	func jsonSupportsCustomTimestampStyle() throws {
		let record = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
			level: .info,
			signal: .metric,
			message: "Measured reminder sync",
			category: "Sync",
			payload: [.init(key: "duration", duration: 1.25)]
		)

		let style = Log.Record.FormatStyle.JSON(timestampFormatStyle: .timestamp)

		let json = try parsedJSONRecord(record.formatted(style))
		let payload = try parsedPayload(from: json)

		#expect(json["timestamp"] as? String == "42")
		#expect(json["level"] as? String == "info")
		#expect(json["signal"] as? String == "Metric")
		#expect(json["category"] as? String == "Sync")
		#expect(json["message"] as? String == "Measured reminder sync")
		#expect((payload["duration"] as? NSNumber)?.doubleValue == 1.25)
	}

	@Test
	func jsonUsesLatestDuplicatePayloadValue() throws {
		let record = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
			level: .info,
			signal: .state,
			message: "Updated result",
			category: "Sync",
			payload: [
				.init(key: "result", value: "Started"),
				.init(key: "result", value: "Finished")
			]
		)

		let json = try parsedJSONRecord(record.formatted(.json))
		let payload = try parsedPayload(from: json)

		#expect(payload["result"] as? String == "Finished")
	}

	@Test
	func jsonOmitsEmptyOptionalFieldsAndFormatsBlankRecordAsEmptyString() throws {
		let structuredRecord = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
			level: .info,
			signal: .state,
			message: "",
			category: "Sync"
		)
		let blankRecord = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
			level: .info,
			message: ""
		)

		let json = try parsedJSONRecord(structuredRecord.formatted(.json))

		#expect(json["message"] == nil)
		#expect(json["payload"] == nil)
		#expect(blankRecord.formatted(.json) == "")
	}

	@Test
	func formatsCanonicalLogLineWithQuotedValuesAndCanonicalKeys() {
		let record = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
			level: .error,
			signal: .diagnostic,
			message: "Failed \"nightly\" sync",
			category: "Background Sync",
			payload: [
				.init(key: "error message", value: "Database path C:\\Logs was unavailable"),
				.init(key: "retry_count", value: 2)
			]
		)

		#expect(record.formatted(.canonicalLogLine) == "[1970-01-01T00:00:42Z] canonical-log-line level=error signal=Diagnostic category=\"Background Sync\" message=\"Failed \\\"nightly\\\" sync\" error_message=\"Database path C:\\\\Logs was unavailable\" retry_count=2")
	}

	@Test
	func canonicalLogLineSupportsCustomTimestampStyle() {
		let record = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
			level: .info,
			signal: .metric,
			message: "Measured reminder sync",
			category: "Sync",
			payload: [.init(key: "duration", duration: 1.25)]
		)

		let style = Log.Record.FormatStyle.CanonicalLogLine(timestampFormatStyle: .timestamp)

		#expect(record.formatted(style) == "[42] canonical-log-line level=info signal=Metric category=Sync message=\"Measured reminder sync\" duration=1.25s")
	}

	@Test
	func consoleLoggerUsesCanonicalLogLineRecordFormatter() {
		let logger = ConsoleLogger(subsystem: "com.mergesort.BroadcastTests", category: "logs")
		let record = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 0)),
			level: .warn,
			signal: .event,
			message: "Reached retry threshold",
			category: "Notifications",
			payload: [.init(key: "attempts", value: 3)]
		)

		#expect(logger.recordFormatter.format(record) == "[1970-01-01T00:00:00Z] canonical-log-line level=warn signal=Event category=Notifications message=\"Reached retry threshold\" attempts=3")
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

private func parsedJSONRecord(_ text: String) throws -> [String: Any] {
	let data = Data(text.utf8)
	let object = try JSONSerialization.jsonObject(with: data)

	return try #require(object as? [String: Any])
}

private func parsedPayload(from json: [String: Any]) throws -> [String: Any] {
	try #require(json["payload"] as? [String: Any])
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
