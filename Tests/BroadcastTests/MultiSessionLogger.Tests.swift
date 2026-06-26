#if MultiSessionLogging
import Boutique
#endif
@testable import Broadcast
import Foundation
import Synchronization
import Testing

extension Trait where Self == ConditionTrait {
	/// Disables the annotated suite or test when the `MultiSessionLogging` package trait is
	/// off, because `MultiSessionLogger` and its Boutique backing are not compiled into that
	/// build. The tests are reported as disabled rather than silently passing.
	static var requiresMultiSessionLogging: Self {
		#if MultiSessionLogging
			.enabled(if: true)
		#else
			.disabled("Requires the MultiSessionLogging package trait")
		#endif
	}
}

@MainActor
@Suite(.requiresMultiSessionLogging)
struct MultiSessionLoggerTests {
	@Test
	func persistsLogsWithDefaultTimestampFormatStyle() async throws {
		#if MultiSessionLogging
			let logger = try await Self.makeLogger(
				dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
			)

			logger.info("Created reminder")
			await logger.flush()

			#expect(logger.logs() == "[Info] @ 1970-01-01T00:00:00Z | Created reminder")
		#else
			Issue.record("MultiSessionLogging is not enabled; this test should not run.")
		#endif
	}

	@Test
	func persistsLogsWithConfiguredTimestamp() async throws {
		#if MultiSessionLogging
			let logger = try await Self.makeLogger(
				dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) },
				timestampFormatStyle: .timestamp
			)

			logger.info("Created reminder")
			await logger.flush()

			#expect(logger.logs() == "[Info] @ 0 | Created reminder")
		#else
			Issue.record("MultiSessionLogging is not enabled; this test should not run.")
		#endif
	}

	@Test
	func persistsMultipleValues() async throws {
		#if MultiSessionLogging
			let logger = try await Self.makeLogger(
				dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
			)

			logger.info("Created", "Reminder", 3)
			await logger.flush()

			#expect(logger.logs() == "[Info] @ 1970-01-01T00:00:00Z | Created, Reminder, 3")
		#else
			Issue.record("MultiSessionLogging is not enabled; this test should not run.")
		#endif
	}

	@Test
	func exposesBufferedRecords() async throws {
		#if MultiSessionLogging
			let logger = try await Self.makeLogger(
				dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
			)

			logger.info(.action, "Created reminder", category: "Reminders", payload: [.init(key: "priority", value: "High")])
			await logger.flush()

			let record = try #require(logger.records().first)

			#expect(logger.records().count == 1)
			#expect(record.timestamp == Log.Timestamp(Date(timeIntervalSince1970: 0)))
			#expect(record.level == .info)
			#expect(record.signal == .action)
			#expect(record.message == "Created reminder")
			#expect(record.category == "Reminders")
			#expect(record.payload == [.init(key: "priority", value: "High")])
		#else
			Issue.record("MultiSessionLogging is not enabled; this test should not run.")
		#endif
	}

	@Test
	func persistsEveryLevel() async throws {
		#if MultiSessionLogging
			let logger = try await Self.makeLogger(
				dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
			)

			logger.debug("Read reminders", 1)
			logger.info("Created reminder", 2)
			logger.warn("Skipped reminder notification", 3)
			logger.error("Failed reminder sync", 4)
			logger.fault("Detected reminder store corruption", 5)
			await logger.flush()

			#expect(logger.logs() == """
			[Debug] @ 1970-01-01T00:00:00Z | Read reminders, 1
			[Info] @ 1970-01-01T00:00:00Z | Created reminder, 2
			[Warn] @ 1970-01-01T00:00:00Z | Skipped reminder notification, 3
			[Error] @ 1970-01-01T00:00:00Z | Failed reminder sync, 4
			[Fault] @ 1970-01-01T00:00:00Z | Detected reminder store corruption, 5
			""")
		#else
			Issue.record("MultiSessionLogging is not enabled; this test should not run.")
		#endif
	}

	@Test
	func waitsForQueuedWritesBeforeReadingLogs() async throws {
		#if MultiSessionLogging
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
		#else
			Issue.record("MultiSessionLogging is not enabled; this test should not run.")
		#endif
	}

	@Test
	func returnsNewestLogsWhenCountIsProvided() async throws {
		#if MultiSessionLogging
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
		#else
			Issue.record("MultiSessionLogging is not enabled; this test should not run.")
		#endif
	}

	@Test
	func removesAllBufferedAndPersistedLogs() async throws {
		#if MultiSessionLogging
			let store = try await Store<Log.Record>(
				storage: SQLiteStorageEngine(directory: .temporary(appendingPath: "BroadcastTests_\(UUID().uuidString)"))!
			)
			let logger = MultiSessionLogger(store: store)

			logger.info("First")
			logger.info("Second")
			await logger.removeAll()

			let restoredLogger = MultiSessionLogger(store: store)
			await restoredLogger.flush()

			#expect(logger.records().isEmpty)
			#expect(logger.logs().isEmpty)
			#expect(restoredLogger.records().isEmpty)
		#else
			Issue.record("MultiSessionLogging is not enabled; this test should not run.")
		#endif
	}
}

#if MultiSessionLogging
	// MARK: Private

	private extension MultiSessionLoggerTests {
		static func makeLogger(dateProvider: Log.DateProvider = .default, timestampFormatStyle: Log.Timestamp.FormatStyle = .default) async throws -> MultiSessionLogger {
			let store = try await Store<Log.Record>(
				storage: SQLiteStorageEngine(directory: .temporary(appendingPath: "BroadcastTests_\(UUID().uuidString)"))!
			)

			return MultiSessionLogger(
				store: store,
				dateProvider: dateProvider,
				timestampFormatStyle: timestampFormatStyle
			)
		}
	}
#endif

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
