@testable import Broadcast
import Foundation
import Testing

struct SessionLoggerTests {
	@Test
	func formatsLogsWithDefaultTimestampFormatStyle() throws {
		let logger = SessionLogger(
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
		)

		logger.info("Created reminder")

		#expect(logger.logs() == "[Info] @ 1970-01-01T00:00:00Z | Created reminder")
	}

	@Test
	func formatsLogsWithConfiguredTimestamp() {
		let logger = SessionLogger(
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) },
			timestampFormatStyle: .timestamp
		)

		logger.info("Created reminder")

		#expect(logger.logs() == "[Info] @ 0 | Created reminder")
	}

	@Test
	func formatsMultipleValues() {
		let logger = SessionLogger(
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
		)

		logger.info("Created", "Reminder", 3)

		#expect(logger.logs() == "[Info] @ 1970-01-01T00:00:00Z | Created, Reminder, 3")
	}

	@Test
	func exposesBufferedRecords() throws {
		let logger = SessionLogger(
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
		)

		logger.info(.action, "Created reminder", category: "Reminders", payload: [.init(key: "priority", value: "High")])

		let record = try #require(logger.records().first)

		#expect(logger.records().count == 1)
		#expect(record.timestamp == Log.Timestamp(Date(timeIntervalSince1970: 0)))
		#expect(record.level == .info)
		#expect(record.signal == .action)
		#expect(record.message == "Created reminder")
		#expect(record.category == "Reminders")
		#expect(record.payload == [.init(key: "priority", value: "High")])
	}

	@Test
	func removesAllBufferedLogs() {
		let logger = SessionLogger()

		logger.info("First")
		logger.info("Second")
		logger.removeAll()

		#expect(logger.records().isEmpty)
		#expect(logger.logs().isEmpty)
	}

	@Test
	func formatsArrayAsSingleValueThroughLog() {
		let logger = SessionLogger(
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
		)
		let log = Log(destinations: [logger])

		log.info(["Groceries", "Errands", "Home"])

		#expect(logger.logs() == "[Info] @ 1970-01-01T00:00:00Z | [\"Groceries\", \"Errands\", \"Home\"]")
	}

	@Test
	func formatsNestedArrayAsSingleValueThroughLog() {
		let logger = SessionLogger(
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
		)
		let log = Log(destinations: [logger])

		log.info([["Groceries"], ["Errands"]])

		#expect(logger.logs() == "[Info] @ 1970-01-01T00:00:00Z | [[\"Groceries\"], [\"Errands\"]]")
	}

	@Test
	func formatsEveryLevel() {
		let logger = SessionLogger(
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
		)

		logger.debug("Read reminders", 1)
		logger.info("Created reminder", 2)
		logger.warn("Skipped reminder notification", 3)
		logger.error("Failed reminder sync", 4)
		logger.fault("Detected reminder store corruption", 5)

		#expect(logger.logs() == """
		[Debug] @ 1970-01-01T00:00:00Z | Read reminders, 1
		[Info] @ 1970-01-01T00:00:00Z | Created reminder, 2
		[Warn] @ 1970-01-01T00:00:00Z | Skipped reminder notification, 3
		[Error] @ 1970-01-01T00:00:00Z | Failed reminder sync, 4
		[Fault] @ 1970-01-01T00:00:00Z | Detected reminder store corruption, 5
		""")
	}

	@Test
	func supportsCustomTimestampFormatting() {
		let logger = SessionLogger(
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 42) },
			timestampFormatStyle: .timestamp
		)

		logger.warn("Reached reminder threshold")

		#expect(logger.logs() == "[Warn] @ 42 | Reached reminder threshold")
	}

	@Test
	func preservesBlankLines() {
		let logger = SessionLogger(
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
		)

		logger.info("First")
		logger.info()
		logger.info("Second")

		#expect(logger.logs() == "[Info] @ 1970-01-01T00:00:00Z | First\n\n[Info] @ 1970-01-01T00:00:00Z | Second")
	}
}
