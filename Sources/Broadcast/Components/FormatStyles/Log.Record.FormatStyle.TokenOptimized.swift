import Foundation

public extension Log.Record.FormatStyle {
	/// Formats records as a compact token-optimized log line.
	///
	/// The token-optimized format is designed for agents, where you have a limited context window,
	/// for example in a prompt. This is ideal for large lists of logs because it keeps Broadcast's
	/// fixed record envelope short, yet preserving application payload names:
	///
	/// `t=42125 l=error s=Diagnostic c="Background Sync" m="Failed sync" p.retry_count=2 p.duration=1250ms`
	///
	/// Record fields use short, stable keys: `t` is the Unix timestamp in
	/// milliseconds, `l` is the level, `s` is the signal, `c` is the category, and
	/// `m` is the message. Payload entries always use the `p.` prefix, such as
	/// `p.retry_count=2`, so caller-provided diagnostic context stays distinct from
	/// Broadcast's record metadata without reserving common payload names.
	///
	/// Values are left bare when safe and quoted when whitespace or delimiters would
	/// make the line ambiguous. Date payload values render as epoch milliseconds,
	/// and duration payload values render as integer milliseconds with an `ms`
	/// suffix, such as `p.duration=1250ms`.
	struct TokenOptimized: Foundation.FormatStyle, Sendable {
		public init() {}

		public func format(_ value: Log.Record) -> String {
			if value.message.isEmpty && value.signal == nil && value.category == nil && value.payload.isEmpty {
				return ""
			}

			return Log.Record.TokenOptimizedRepresentation(record: value)
				.formatted()
		}
	}
}

// MARK: FormatStyle

public extension FormatStyle where Self == Log.Record.FormatStyle.TokenOptimized {
	/// A compact record format optimized for token-sensitive text contexts.
	static var tokenOptimized: Self {
		Self()
	}
}

// MARK: Log.Record.Formatter

public extension Log.Record.Formatter {
	/// A type-erased compact record formatter optimized for token-sensitive text contexts.
	static var tokenOptimized: Self {
		Self(.tokenOptimized)
	}
}
