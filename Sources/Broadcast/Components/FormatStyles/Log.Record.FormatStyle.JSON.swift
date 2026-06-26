import Foundation

public extension Log.Record.FormatStyle {
	/// Formats records as JSON that can be inspected with JSON tools.
	///
	/// The JSON output is designed for export and ingestion, not as Broadcast's
	/// internal `Codable` storage shape. Broadcast renders stable top-level logging
	/// fields first, then includes typed payload values under `payload`.
	///
	/// Exporting multiple records with this formatter, one record per line, produces
	/// JSON Lines-compatible output while keeping the formatter name focused on the
	/// individual record shape.
	struct JSON: Foundation.FormatStyle, Sendable {
		private let timestampFormatStyle: Log.Timestamp.FormatStyle

		public init(timestampFormatStyle: Log.Timestamp.FormatStyle = .default) {
			self.timestampFormatStyle = timestampFormatStyle
		}

		public func format(_ value: Log.Record) -> String {
			if value.message.isEmpty && value.signal == nil && value.category == nil && value.payload.isEmpty {
				return ""
			}

			let encoder = JSONEncoder()
			encoder.outputFormatting = [.withoutEscapingSlashes]

			do {
				let data = try encoder.encode(
					Log.Record.JSONRepresentation(
						record: value,
						timestampFormatStyle: self.timestampFormatStyle
					)
				)
				return String(decoding: data, as: UTF8.self)
			} catch {
				return ""
			}
		}
	}
}

// MARK: FormatStyle

public extension FormatStyle where Self == Log.Record.FormatStyle.JSON {
	/// A structured JSON record format.
	static var json: Self {
		Self()
	}
}

// MARK: Log.Record.Formatter

public extension Log.Record.Formatter {
	/// A type-erased structured JSON record formatter.
	static var json: Self {
		Self(.json)
	}
}
