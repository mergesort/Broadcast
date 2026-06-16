import Foundation

public extension Log {
	/// The semantic representation of a structured log before it is rendered.
	///
	/// ``Log`` forwards structured calls to each ``LoggingDestination`` as semantic
	/// components. Use ``Log/Record`` directly when you need to format a structured log
	/// yourself, test exact structured components, or build a custom formatter. Most
	/// app call-sites should use structured ``Log`` methods such as
	/// ``Log/info(_:_:category:payload:)`` instead.
	struct Record: Codable, Identifiable, Sendable, Equatable {
		/// A stable identifier for this record.
		public let id: UUID

		/// The time associated with this record.
		public let timestamp: Log.Timestamp

		/// The severity level associated with this record.
		public let level: Log.Level

		/// The intent of this log entry.
		public let signal: Log.Signal?

		/// The human-readable event message.
		public let message: String

		/// The area or subsystem this log belongs to.
		public let category: Log.Category?

		/// Ordered diagnostic context for the event.
		public let payload: [Log.Payload]

		public init(id: UUID = UUID(), timestamp: Log.Timestamp = .now, level: Log.Level, signal: Log.Signal, message: String, category: Log.Category, payload: [Log.Payload] = []) {
			self.id = id
			self.timestamp = timestamp
			self.level = level
			self.signal = signal
			self.message = message
			self.category = category
			self.payload = payload
		}

		init(id: UUID = UUID(), timestamp: Log.Timestamp = .now, level: Log.Level, message: String) {
			self.id = id
			self.timestamp = timestamp
			self.level = level
			self.signal = nil
			self.message = message
			self.category = nil
			self.payload = []
		}
	}
}
