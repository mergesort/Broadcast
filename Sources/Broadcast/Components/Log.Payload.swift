import Foundation

public extension Log {
	/// Typed context attached to a structured log.
	///
	/// Payloads are where most of a log's useful context lives: identifiers, counts,
	/// dates, durations, outcomes, errors, and anything else that helps explain what
	/// happened. Prefer app-specific helper factories for repeated keys, such as
	/// `Log.Payload.priority(_:)` or `Log.Payload.dueDate(_:)`, so spelling, ordering,
	/// and value formatting stay consistent. Avoid storing secrets, tokens, or
	/// sensitive user data in payloads.
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

// MARK: Convenience Payloads

public extension Log.Payload {
	/// Creates a string payload with a custom key.
	static func string(_ key: String, _ value: String?) -> Self {
		Self(key: key, value: value)
	}

	/// Creates a boolean payload with a custom key.
	static func bool(_ key: String, _ value: Bool) -> Self {
		Self(key: key, value: value)
	}

	/// Creates an integer payload with a custom key.
	static func int(_ key: String, _ value: Int) -> Self {
		Self(key: key, value: value)
	}

	/// Creates a UUID payload with a custom key.
	static func uuid(_ key: String, _ value: UUID?) -> Self {
		Self(key: key, value: value)
	}

	/// Creates a URL payload with a custom key.
	static func url(_ key: String, _ value: URL?) -> Self {
		Self(key: key, value: value)
	}

	/// Creates a date payload with a custom key.
	static func date(_ key: String, _ value: Date?) -> Self {
		Self(key: key, value: value)
	}

	/// Creates a duration payload with a custom key.
	static func duration(_ key: String = "duration", seconds: TimeInterval) -> Self {
		Self(key: key, duration: seconds)
	}

	/// Creates an error payload.
	static func error(_ error: any Error) -> Self {
		Self(key: "error", value: error)
	}

	/// Creates an error payload with a custom key.
	static func error(_ key: String, _ error: any Error) -> Self {
		Self(key: key, value: error)
	}

	/// Creates a count payload.
	static func count(_ count: Int) -> Self {
		Self(key: "count", value: count)
	}

	/// Creates an identifier payload from a UUID.
	static func id(_ id: UUID?) -> Self {
		Self(key: "id", value: id)
	}

	/// Creates an identifier payload from a string.
	static func id(_ id: String) -> Self {
		Self(key: "id", value: id)
	}

	/// Creates a timestamp payload.
	static func timestamp(_ timestamp: Date?) -> Self {
		Self(key: "timestamp", value: timestamp)
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
