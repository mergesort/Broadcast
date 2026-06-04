public extension Log {
	/// The intent of a structured log entry.
	///
	/// Use signals to make logs easier to scan and filter across categories. For
	/// example, ``Log.Signal/action`` usually describes something the app attempted,
	/// while ``Log.Signal/state`` describes a meaningful state transition or decision.
	/// Broadcast ships common defaults; apps can add domain-specific signals only when
	/// those defaults do not describe the event clearly.
	struct Signal: Codable, Sendable, Equatable {
		/// The text rendered in structured log output.
		public let identifier: String

		public init(identifier: String) {
			self.identifier = identifier
		}
	}
}

// MARK: ExpressibleByStringLiteral

extension Log.Signal: ExpressibleByStringLiteral {
	public init(stringLiteral value: StaticString) {
		self = Log.Signal(identifier: "\(value)")
	}
}

// MARK: Signals

public extension Log.Signal {
	/// A user, system, or app operation that was attempted or completed.
	static let action: Self = "Action"

	/// A meaningful state transition, derived state, or decision.
	static let state: Self = "State"

	/// A noteworthy occurrence that does not fit cleanly as an action or state.
	static let event: Self = "Event"

	/// A measured value or counter that should be treated as diagnostic telemetry.
	static let metric: Self = "Metric"

	/// A support-oriented diagnostic entry intended to explain behavior after the fact.
	static let diagnostic: Self = "Diagnostic"
}
