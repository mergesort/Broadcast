import Foundation

public extension Log.Record {
	/// A type-erased formatter for ``Log/Record`` values.
	///
	/// ``LoggingDestination`` uses this concrete type for its
	/// ``LoggingDestination/recordFormatter`` property so destinations can use any
	/// custom record formatter without changing the structured logging call-site API.
	///
	/// Define a custom formatter by conforming to `Foundation.FormatStyle` with
	/// `FormatStyle.FormatInput` equal to ``Log/Record`` and
	/// `FormatStyle.FormatOutput` equal to `String`:
	///
	/// ```swift
	/// struct CompactRecordFormatStyle: Foundation.FormatStyle, Sendable {
	/// 	func format(_ value: Log.Record) -> String {
	/// 		let prefix = [
	/// 			value.signal?.identifier,
	/// 			value.category?.identifier
	/// 		]
	/// 		.compactMap({ $0 })
	/// 		.joined(separator: "/")
	///
	/// 		if prefix.isEmpty {
	/// 			return value.message
	/// 		} else {
	/// 			return "\(prefix): \(value.message)"
	/// 		}
	/// 	}
	/// }
	///
	/// extension FormatStyle where Self == CompactRecordFormatStyle {
	/// 	static var compactRecord: Self {
	/// 		Self()
	/// 	}
	/// }
	/// ```
	///
	/// Use that formatter directly for one-off record formatting:
	///
	/// ```swift
	/// let text = record.formatted(.compactRecord)
	/// ```
	///
	/// Or wrap it in ``Log/Record/Formatter`` when configuring a destination:
	///
	/// ```swift
	/// final class CompactLoggingDestination: LoggingDestination {
	/// 	var recordFormatter: Log.Record.Formatter {
	/// 		Log.Record.Formatter(.compactRecord)
	/// 	}
	///
	/// 	func log(_ record: Log.Record) {
	/// 		let text = self.recordFormatter.format(record)
	/// 		// Write `text` to this destination.
	/// 	}
	/// }
	/// ```
	///
	/// ``Log/Record/Formatter`` intentionally does not conform to
	/// `Foundation.FormatStyle` because closure-backed type erasure cannot truthfully
	/// satisfy `FormatStyle`'s `Codable`, `Hashable`, and `Equatable` requirements.
	/// Use a concrete `Foundation.FormatStyle` for direct
	/// ``Log/Record/formatted(_:)`` calls, and use this type when storing a formatter
	/// on a destination.
	struct Formatter: Sendable {
		private let formatRecord: @Sendable (Log.Record) -> String

		/// Creates a type-erased record formatter from a formatting closure.
		public init(format: @escaping @Sendable (Log.Record) -> String) {
			self.formatRecord = format
		}

		/// Creates a type-erased record formatter from a Swift `Foundation.FormatStyle`.
		public init<Style: Foundation.FormatStyle & Sendable>(_ style: Style) where Style.FormatInput == Log.Record, Style.FormatOutput == String {
			self.formatRecord = { record in
				record.formatted(style)
			}
		}

		/// Creates Broadcast's default record formatter with a custom timestamp style.
		public init(timestampFormatStyle: Log.Timestamp.FormatStyle) {
			self.init(Log.Record.FormatStyle(timestampFormatStyle: timestampFormatStyle))
		}

		/// Formats a semantic structured log record.
		public func format(_ value: Log.Record) -> String {
			self.formatRecord(value)
		}
	}
}

// MARK: Log.Record.Formatter

public extension Log.Record.Formatter {
	/// Broadcast's default type-erased structured record format.
	static var `default`: Self {
		Self(timestampFormatStyle: .default)
	}
}
