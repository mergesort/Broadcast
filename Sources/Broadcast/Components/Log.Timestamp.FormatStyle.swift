import Foundation

public extension Log.Timestamp {
	/// Broadcast's default timestamp formatter.
	///
	/// Apps usually use the default ``Log/Timestamp/FormatStyle``. Use another provided
	/// style when support exports need a different timestamp shape:
	///
	/// ```swift
	/// let logger = SessionLogger(timestampFormatStyle: .timestamp)
	/// ```
	///
	/// `SessionLogger` and `MultiSessionLogger` currently accept this concrete
	/// ``Log/Timestamp/FormatStyle`` for logger-level timestamp configuration. If an
	/// app needs a fully custom timestamp representation, define a separate
	/// `Foundation.FormatStyle` for direct ``Log/Timestamp`` formatting or for use
	/// inside a custom ``LoggingDestination``.
	struct FormatStyle: Foundation.FormatStyle, Codable, Hashable, Sendable {
		private let style: Style

		public init(_ style: Style = .iso8601) {
			self.style = style
		}

		public func format(_ value: Log.Timestamp) -> String {
			switch self.style {
			case .iso8601: value.date.formatted(.iso8601)
			case .timestamp: String(Int(value.date.timeIntervalSince1970))
			}
		}
	}

	/// Formats this timestamp with a Swift `Foundation.FormatStyle`.
	///
	/// Define a custom timestamp format style when an app wants a timestamp shape that
	/// does not match Broadcast's built-in ``Log/Timestamp/FormatStyle/default`` or
	/// `FormatStyle.timestamp` styles:
	///
	/// ```swift
	/// struct SupportTimestampFormatStyle: Foundation.FormatStyle {
	/// 	func format(_ value: Log.Timestamp) -> String {
	/// 		value.date.formatted(date: .abbreviated, time: .shortened)
	/// 	}
	/// }
	///
	/// extension FormatStyle where Self == SupportTimestampFormatStyle {
	/// 	static var supportTimestamp: Self {
	/// 		Self()
	/// 	}
	/// }
	///
	/// let timestamp = Log.Timestamp.now
	/// let text = timestamp.formatted(.supportTimestamp)
	/// ```
	///
	/// Use this direct formatting path in custom destinations that own their timestamp
	/// rendering. Broadcast's concrete buffered loggers use ``Log/Timestamp/FormatStyle``
	/// for their logger-level `timestampFormatStyle` parameter.
	func formatted<Style: Foundation.FormatStyle>(_ style: Style) -> Style.FormatOutput where Style.FormatInput == Self {
		style.format(self)
	}
}

// MARK: Log.Timestamp.FormatStyle.Style

public extension Log.Timestamp.FormatStyle {
	/// Supported timestamp formats for Broadcast's concrete timestamp style.
	enum Style: Codable, Hashable, Sendable {
		case iso8601
		case timestamp
	}
}

public extension FormatStyle where Self == Log.Timestamp.FormatStyle {
	/// Broadcast's default timestamp format.
	static var `default`: Self {
		Self()
	}

	/// A timestamp format that renders an integer Unix timestamp.
	static var timestamp: Self {
		Self(.timestamp)
	}
}
