import Foundation

public extension Log {
	/// A timestamp value used by buffered loggers.
	///
	/// ``SessionLogger`` and ``MultiSessionLogger`` wrap dates in ``Log/Timestamp`` so
	/// timestamp rendering can use the same Swift `Foundation.FormatStyle` pattern as
	/// structured records and payloads.
	struct Timestamp: Codable, Sendable, Equatable {
		/// The date represented by this timestamp.
		public let date: Date

		public init(_ date: Date = .now) {
			self.date = date
		}
	}
}

public extension Log.Timestamp {
	/// A timestamp representing the current wall-clock date.
	static var now: Self {
		Self()
	}
}
