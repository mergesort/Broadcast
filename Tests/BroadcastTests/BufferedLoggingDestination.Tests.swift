import Broadcast
import Foundation
import Testing

struct BufferedLoggingDestinationTests {
	@Test
	func exportsWithDefaultFormatterThroughProtocol() {
		let destination: any BufferedLoggingDestination = DefaultBufferedDestination()
		destination.log(Self.record("First", at: 1))

		#expect(destination.logs() == "[Info | State | Sync] @ 1970-01-01T00:00:01Z | First")
	}

	@Test
	func exportsWithCustomFormatterThroughProtocol() {
		let destination: any BufferedLoggingDestination = CustomBufferedDestination()
		destination.log(Self.record("First", at: 1))
		destination.log(Self.record("Second", at: 2))

		#expect(destination.logs() == "custom: First\ncustom: Second")
		#expect(destination.logs(count: 1) == "custom: Second")
		#expect(destination.logs(count: nil) == "custom: First\ncustom: Second")
	}

	private static func record(_ message: String, at seconds: TimeInterval) -> Log.Record {
		Log.Record(
			timestamp: Log.Timestamp(Date(timeIntervalSince1970: seconds)),
			level: .info,
			signal: .state,
			message: message,
			category: "Sync"
		)
	}
}

private final class DefaultBufferedDestination: BufferedLoggingDestination {
	private var storage: [Log.Record] = []

	func log(_ record: Log.Record) {
		self.storage.append(record)
	}

	func records() -> [Log.Record] {
		self.storage
	}
}

private final class CustomBufferedDestination: BufferedLoggingDestination {
	let recordFormatter = Log.Record.Formatter { "custom: \($0.message)" }
	private var storage: [Log.Record] = []

	func log(_ record: Log.Record) {
		self.storage.append(record)
	}

	func records() -> [Log.Record] {
		self.storage
	}
}
