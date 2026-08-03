#if SwiftLogging
import Broadcast
import Foundation
import Logging
import Synchronization
import Testing

struct SwiftLogDestinationTests {
	@Test
	func forwardsStructuredRecordsToSwiftLog() throws {
		let capturedEvents = CapturedSwiftLogEvents()
		let logger = Logger(label: "com.example.broadcast") { _ in
			CapturingSwiftLogHandler(capturedEvents: capturedEvents)
		}
		let destination = SwiftLogDestination(logger: logger)
		let record = Log.Record(
			id: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!,
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
			level: .warn,
			signal: .state,
			message: "Loaded reminders",
			category: "Reminders",
			payload: [
				.string("result", "Success"),
				.int("reminderCount", 3),
				.bool("isInitialLoad", true)
			]
		)

		destination.log(record)

		let event = try #require(capturedEvents.events().first)
		let metadata = try #require(event.metadata)

		#expect(event.level == .warning)
		#expect(event.message.description == "Loaded reminders")
		#expect(metadata.stringValue(forKey: "broadcast.id") == "00000000-0000-4000-8000-000000000001")
		#expect(metadata.stringValue(forKey: "broadcast.timestamp") == "1970-01-01T00:00:42Z")
		#expect(metadata.stringValue(forKey: "broadcast.signal") == "State")
		#expect(metadata.stringValue(forKey: "broadcast.category") == "Reminders")
		#expect(metadata.stringValue(forKey: "payload.result") == "Success")
		#expect(metadata.stringValue(forKey: "payload.reminderCount") == "3")
		#expect(metadata.stringValue(forKey: "payload.isInitialLoad") == "true")
	}

	@Test
	func mapsFaultsToCriticalSwiftLogEvents() throws {
		let capturedEvents = CapturedSwiftLogEvents()
		let logger = Logger(label: "com.example.broadcast") { _ in
			CapturingSwiftLogHandler(capturedEvents: capturedEvents)
		}
		let destination = SwiftLogDestination(logger: logger)
		let record = Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: 42)),
			level: .fault,
			signal: .diagnostic,
			message: "Failed sync",
			category: "Sync"
		)

		destination.log(record)

		let event = try #require(capturedEvents.events().first)

		#expect(event.level == .critical)
		#expect(event.message.description == "Failed sync")
	}
}

// MARK: CapturedSwiftLogEvents

private final class CapturedSwiftLogEvents: Sendable {
	private let storage = Mutex<[LogEvent]>([])

	func append(_ event: LogEvent) {
		self.storage.withLock {
			$0.append(event)
		}
	}

	func events() -> [LogEvent] {
		self.storage.withLock {
			$0
		}
	}
}

// MARK: CapturingSwiftLogHandler

private struct CapturingSwiftLogHandler: LogHandler {
	let capturedEvents: CapturedSwiftLogEvents
	var metadataProvider: Logger.MetadataProvider?
	var metadata: Logger.Metadata = [:]
	var logLevel: Logger.Level = .trace

	subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
		get {
			self.metadata[metadataKey]
		}
		set {
			self.metadata[metadataKey] = newValue
		}
	}

	func log(event: LogEvent) {
		self.capturedEvents.append(event)
	}
}

// MARK: Logger.Metadata

private extension Logger.Metadata {
	func stringValue(forKey key: String) -> String? {
		guard let value = self[key] else {
			return nil
		}

		switch value {
		case .string(let string):
			return string
		case .stringConvertible(let value):
			return value.description
		case .array, .dictionary:
			return nil
		}
	}
}
#endif
