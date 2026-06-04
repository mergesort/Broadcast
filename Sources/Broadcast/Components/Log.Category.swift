public extension Log {
	/// A human-readable area or subsystem for a structured log.
	///
	/// Categories describe where an event belongs, such as `"Reminders"`, `"Sync"`,
	/// or `"Payments"`. Apps commonly add static members in their integration layer,
	/// like `extension Log.Category { static let reminders: Self = "Reminders" }`,
	/// so call-sites can reuse durable vocabulary instead of hardcoding strings.
	struct Category: Codable, Sendable, Equatable {
		/// The text rendered in structured log output.
		public let identifier: String

		public init(identifier: String) {
			self.identifier = identifier
		}
	}
}

// MARK: ExpressibleByStringLiteral

extension Log.Category: ExpressibleByStringLiteral {
	public init(stringLiteral value: StaticString) {
		self = Log.Category(identifier: "\(value)")
	}
}
