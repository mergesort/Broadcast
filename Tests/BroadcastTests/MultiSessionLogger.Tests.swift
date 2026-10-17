#if MultiSessionLogging && canImport(Boutique)
import Boutique
@testable import Broadcast
import Foundation
import Synchronization
import Testing

@MainActor
struct MultiSessionLoggerTests {
	@Test
	func formatsBufferedLogsWithDefaultTimestampFormatStyle() async throws {
		let logger = try await Self.makeLogger(
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
		)

		logger.info("Created reminder")
		await logger.flush()

		#expect(logger.logs() == "[Info] @ 1970-01-01T00:00:00Z | Created reminder")
	}

	@Test
	func formatsBufferedLogsWithConfiguredTimestamp() async throws {
		let logger = try await Self.makeLogger(
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) },
			timestampFormatStyle: .timestamp
		)

		logger.info("Created reminder")
		await logger.flush()

		#expect(logger.logs() == "[Info] @ 0 | Created reminder")
	}

	@Test
	func restoresStructuredRecords() async throws {
		let directoryName = "BroadcastTests_\(UUID().uuidString)"
		let logger = try await Self.makeLogger(
			directoryName: directoryName,
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
		)

		let payload: [Log.Payload] = [
			.init(key: "priority", value: "High"),
			.init(key: "count", value: 3),
			.init(key: "optionalDate", value: nil as Date?),
			.init(key: "elapsed", duration: 1.25)
		]
		logger.info(.action, "Created reminder", category: "Reminders", payload: payload)
		await logger.flush()
		let restoredLogger = try await Self.makeLogger(directoryName: directoryName)
		await restoredLogger.flush()

		#expect(restoredLogger.records() == logger.records())

		let record = try #require(restoredLogger.records().first)

		#expect(restoredLogger.records().count == 1)
		#expect(record.timestamp == Log.Timestamp(Date(timeIntervalSince1970: 0)))
		#expect(record.level == .info)
		#expect(record.signal == .action)
		#expect(record.message == "Created reminder")
		#expect(record.category == "Reminders")
		#expect(record.payload == payload)
	}

	@Test
	func persistsEveryLevel() async throws {
		let directoryName = "BroadcastTests_\(UUID().uuidString)"
		let logger = try await Self.makeLogger(
			directoryName: directoryName,
			dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
		)

		logger.debug("Read reminders", 1)
		logger.info("Created reminder", 2)
		logger.warn("Skipped reminder notification", 3)
		logger.error("Failed reminder sync", 4)
		logger.fault("Detected reminder store corruption", 5)
		await logger.flush()
		let restoredLogger = try await Self.makeLogger(directoryName: directoryName)
		await restoredLogger.flush()

		#expect(Dictionary(uniqueKeysWithValues: restoredLogger.records().map({ ($0.id, $0) })) == Dictionary(uniqueKeysWithValues: logger.records().map({ ($0.id, $0) })))
		#expect(logger.logs() == """
		[Debug] @ 1970-01-01T00:00:00Z | Read reminders, 1
		[Info] @ 1970-01-01T00:00:00Z | Created reminder, 2
		[Warn] @ 1970-01-01T00:00:00Z | Skipped reminder notification, 3
		[Error] @ 1970-01-01T00:00:00Z | Failed reminder sync, 4
		[Fault] @ 1970-01-01T00:00:00Z | Detected reminder store corruption, 5
		""")
	}

	@Test
	func preservesBufferedWriteOrder() async throws {
		let dateProvider = SequentialDateProvider(
			dates: [
				Date(timeIntervalSince1970: 1),
				Date(timeIntervalSince1970: 2),
				Date(timeIntervalSince1970: 3)
			]
		)

		let logger = try await Self.makeLogger(
			dateProvider: Log.DateProvider { dateProvider.nextDate() },
			timestampFormatStyle: .timestamp
		)

		logger.info("First")
		logger.info("Second")
		logger.info("Third")
		await logger.flush()

		#expect(logger.logs() == "[Info] @ 1 | First\n[Info] @ 2 | Second\n[Info] @ 3 | Third")
	}

	@Test
	func returnsNewestLogsWhenCountIsProvided() async throws {
		let dateProvider = SequentialDateProvider(
			dates: [
				Date(timeIntervalSince1970: 1),
				Date(timeIntervalSince1970: 2),
				Date(timeIntervalSince1970: 3)
			]
		)

		let logger = try await Self.makeLogger(
			dateProvider: Log.DateProvider { dateProvider.nextDate() },
			timestampFormatStyle: .timestamp
		)

		logger.info("First")
		logger.info("Second")
		logger.info("Third")

		await logger.flush()

		#expect(logger.logs(count: 2) == "[Info] @ 3 | Third\n[Info] @ 2 | Second")
	}

	@Test
	func removesAllBufferedAndPersistedLogs() async throws {
		let directoryName = "BroadcastTests_\(UUID().uuidString)"
		let logger = try await Self.makeLogger(directoryName: directoryName)

		logger.info("First")
		logger.info("Second")
		await logger.flush()

		let persistedLogger = try await Self.makeLogger(directoryName: directoryName)
		await persistedLogger.flush()
		#expect(Dictionary(uniqueKeysWithValues: persistedLogger.records().map({ ($0.id, $0) })) == Dictionary(uniqueKeysWithValues: logger.records().map({ ($0.id, $0) })))
		#expect(persistedLogger.records().count == 2)

		logger.info("Third")
		await logger.removeAll()

		let restoredLogger = try await Self.makeLogger(directoryName: directoryName)
		await restoredLogger.flush()

		#expect(logger.records().isEmpty)
		#expect(logger.logs().isEmpty)
		#expect(restoredLogger.records().isEmpty)
	}
}

// MARK: Private

private extension MultiSessionLoggerTests {
	static func makeLogger(directoryName: String = "BroadcastTests_\(UUID().uuidString)", dateProvider: Log.DateProvider = .default, timestampFormatStyle: Log.Timestamp.FormatStyle = .default) async throws -> MultiSessionLogger {
		let store = try await Store<Log.Record>(
			storage: SQLiteStorageEngine(directory: .temporary(appendingPath: directoryName))!
		)

		return MultiSessionLogger(
			store: store,
			dateProvider: dateProvider,
			timestampFormatStyle: timestampFormatStyle
		)
	}
}

// MARK: SequentialDateProvider

private final class SequentialDateProvider: Sendable {
	private let dates: Mutex<[Date]>

	init(dates: [Date]) {
		self.dates = Mutex(dates)
	}

	func nextDate() -> Date {
		self.dates.withLock {
			$0.removeFirst()
		}
	}
}
#endif
