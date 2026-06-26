import Foundation
import Synchronization

/// An in-memory destination for logs from the current launch.
///
/// Use ``SessionLogger`` for support-log export, bug report attachments, AI
/// debugging exports, or tests that need to inspect what your app logged during
/// this process. It does not persist across app restarts; use ``MultiSessionLogger``
/// when historical logs should survive relaunches.
public final class SessionLogger: BufferedLoggingDestination {
	public let dateProvider: Log.DateProvider
	private let storage = SessionLogStorage()
	private let timestampFormatStyle: Log.Timestamp.FormatStyle

	/// Creates a session buffer with configurable timestamp behavior.
	///
	/// ``Log/DateProvider/default`` and the default ``Log/Timestamp/FormatStyle`` are
	/// suitable for production. Inject fixed values in tests when log output must be
	/// deterministic.
	public init(dateProvider: Log.DateProvider = .default, timestampFormatStyle: Log.Timestamp.FormatStyle = .default) {
		self.dateProvider = dateProvider
		self.timestampFormatStyle = timestampFormatStyle
	}

	public var recordFormatter: Log.Record.Formatter {
		Log.Record.Formatter(timestampFormatStyle: self.timestampFormatStyle)
	}

	public func log(_ record: Log.Record) {
		self.storage.append(record)
	}

	/// Returns all records captured during this process.
	public func records() -> [Log.Record] {
		self.storage.records()
	}

	/// Removes all records captured during this process.
	public func removeAll() {
		self.storage.removeAll()
	}
}

// MARK: SessionLogStorage

private final class SessionLogStorage: Sendable {
	private let recordStorage = Mutex<[Log.Record]>([])

	func append(_ record: Log.Record) {
		self.recordStorage.withLock {
			$0.append(record)
		}
	}

	func records() -> [Log.Record] {
		self.recordStorage.withLock {
			$0
		}
	}

	func removeAll() {
		self.recordStorage.withLock {
			$0.removeAll()
		}
	}
}
