import Foundation

public extension Log.Record.FormatStyle {
	/// Formats records as a Stripe-style canonical log line.
	///
	/// Inspired by Stripe's Canonical Log Lines:
	/// https://stripe.com/blog/canonical-log-lines
	///
	/// A canonical log line is one dense, queryable line for a unit of work. Broadcast
	/// keeps the semantic ``Log.Record`` as the source of truth, then renders it as:
	///
	/// `[timestamp] canonical-log-line level=info signal=State category=Sync message="Finished sync" duration=1.25s`
	///
	/// The fixed `canonical-log-line` marker makes these records easy to filter in a
	/// log processor. The remaining fields use `key=value` pairs: Broadcast-provided
	/// fields come first, followed by caller-provided payload in its original order.
	/// Values are left bare when safe and quoted when spaces or delimiters would make
	/// the line ambiguous.
	struct CanonicalLogLine: Foundation.FormatStyle, Sendable {
		private let timestampFormatStyle: Log.Timestamp.FormatStyle

		public init(timestampFormatStyle: Log.Timestamp.FormatStyle = .default) {
			self.timestampFormatStyle = timestampFormatStyle
		}

		public func format(_ value: Log.Record) -> String {
			if value.message.isEmpty && value.signal == nil && value.category == nil && value.payload.isEmpty {
				return ""
			}

			return Log.Record.CanonicalLogLineRepresentation(
				record: value,
				timestampFormatStyle: self.timestampFormatStyle
			)
			.formatted()
		}
	}
}

// MARK: FormatStyle

public extension FormatStyle where Self == Log.Record.FormatStyle.CanonicalLogLine {
	/// A Stripe-style canonical log line record format.
	static var canonicalLogLine: Self {
		Self()
	}
}

// MARK: Log.Record.Formatter

public extension Log.Record.Formatter {
	/// A type-erased Stripe-style canonical log line record formatter.
	static var canonicalLogLine: Self {
		Self(.canonicalLogLine)
	}
}
