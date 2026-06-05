import Foundation

public extension Log.Record {
	/// Formats this record with a Swift ``Foundation/FormatStyle``.
	///
	/// Use this for one-off formatting, assertions, or custom exports. To make a
	/// ``LoggingDestination`` use a custom record format for every structured log,
	/// wrap the style in ``Log.Record.Formatter`` and return it from
	/// ``LoggingDestination/recordFormatter``.
	func formatted<Style: Foundation.FormatStyle>(_ style: Style) -> Style.FormatOutput where Style.FormatInput == Self {
		style.format(self)
	}

	/// Broadcast's default single-line structured log format.
	///
	/// The default format is intentionally human-readable and support-log friendly:
	/// `[Level | Signal | Category] @ Timestamp | Message | payload=[key=value]`. Apps that need another
	/// shape can provide their own ``Foundation/FormatStyle`` for ``Log.Record`` and
	/// configure destinations with ``Log.Record.Formatter``.
	struct FormatStyle: Foundation.FormatStyle, Sendable {
		let timestampFormatStyle: Log.Timestamp.FormatStyle

		public init(timestampFormatStyle: Log.Timestamp.FormatStyle = .default) {
			self.timestampFormatStyle = timestampFormatStyle
		}
	}
}

// MARK: FormatStyle

public extension FormatStyle where Self == Log.Record.FormatStyle {
	/// Broadcast's default structured record format.
	static var `default`: Self {
		Self()
	}
}
