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

	/// Broadcast's default single-line structured log formatter.
	///
	/// The default format is intentionally human-readable and support-log friendly:
	/// `[Level | Signal | Category] @ Timestamp | Message | payload=[key=value]`. Apps that need another
	/// shape can provide their own ``Foundation/FormatStyle`` for ``Log.Record`` and
	/// configure destinations with ``Log.Record.Formatter``.
	struct FormatStyle: Foundation.FormatStyle, Sendable {
		private let timestampFormatStyle: Log.Timestamp.FormatStyle

		public init(timestampFormatStyle: Log.Timestamp.FormatStyle = .default) {
			self.timestampFormatStyle = timestampFormatStyle
		}

		public func format(_ value: Log.Record) -> String {
			if value.message.isEmpty && value.signal == nil && value.category == nil && value.payload.isEmpty {
				return ""
			}

			let prefix = [
				value.level.rawValue.capitalized,
				value.signal?.identifier,
				value.category?.identifier
			]
			.compactMap({ $0 })
			.joined(separator: " | ")

			var components = [
				"[\(prefix)] @ \(value.timestamp.formatted(self.timestampFormatStyle))",
				value.message
			]

			if !value.payload.isEmpty {
				components.append(
					"payload=[\(value.payload.map({ $0.formatted(.logPayload) }).joined(separator: ", "))]"
				)
			}

			return components.joined(separator: " | ")
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
