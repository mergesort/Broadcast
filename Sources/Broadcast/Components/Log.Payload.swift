import Foundation

public extension Log {
	/// A typed key-value pair attached to a structured log.
	///
	/// Payloads are where durable diagnostic context belongs: identifiers, counts,
	/// decisions, timings, and errors. Prefer typed app-specific helper factories for
	/// repeated keys, such as `Log.Payload.priority(_:)` or
	/// `Log.Payload.dueDate(_:)`, so spelling, ordering, and value formatting stay
	/// consistent. Avoid storing secrets, tokens, or sensitive user data in payloads.
	struct Payload: Codable, Sendable, Equatable {
		/// The stable diagnostic key rendered before the payload value.
		public let key: String

		let value: Value

		public init(key: String, value: String) {
			self.init(key: key, value: .string(value))
		}

		public init(key: String, value: String?) {
			self.init(key: key, value: .string(value))
		}

		public init(key: String, value: Bool) {
			self.init(key: key, value: .bool(value))
		}

		public init(key: String, value: Int) {
			self.init(key: key, value: .int(value))
		}

		public init(key: String, value: UUID) {
			self.init(key: key, value: .uuid(value))
		}

		public init(key: String, value: UUID?) {
			self.init(key: key, value: .uuid(value))
		}

		public init(key: String, value: URL) {
			self.init(key: key, value: .url(value))
		}

		public init(key: String, value: URL?) {
			self.init(key: key, value: .url(value))
		}

		public init(key: String, value: Date) {
			self.init(key: key, value: .date(value))
		}

		public init(key: String, value: Date?) {
			self.init(key: key, value: .date(value))
		}

		public init(key: String, value: any Error) {
			self.init(key: key, value: .error(value.localizedDescription))
		}

		public init(key: String, duration seconds: TimeInterval) {
			self.init(key: key, value: .duration(seconds))
		}
	}
}

// MARK: Internal

extension Log.Payload {
	init(key: String, value: Value) {
		self.key = key
		self.value = value
	}
}

// MARK: Log.Payload.Value

extension Log.Payload {
	enum Value: Codable, Sendable, Equatable {
		case string(String?)
		case bool(Bool)
		case int(Int)
		case uuid(UUID?)
		case url(URL?)
		case date(Date?)
		case error(String)
		case duration(TimeInterval)
	}
}
