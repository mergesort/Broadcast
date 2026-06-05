import Foundation

extension Log.Record {
	struct CanonicalLogLineRepresentation {
		let timestamp: String
		let fields: [CanonicalLogLineField]

		init(record: Log.Record, timestampFormatStyle: Log.Timestamp.FormatStyle) {
			self.timestamp = record.timestamp.formatted(timestampFormatStyle)
			self.fields = Self.fields(for: record)
		}

		func formatted() -> String {
			let fields = self.fields
				.map({ $0.formatted() })
				.joined(separator: " ")

			return "[\(self.timestamp)] canonical-log-line \(fields)"
		}
	}
}

// MARK: Private

private extension Log.Record.CanonicalLogLineRepresentation {
	static func fields(for record: Log.Record) -> [Log.Record.CanonicalLogLineField] {
		var fields = [
			Log.Record.CanonicalLogLineField(key: "level", value: record.level.rawValue)
		]

		if let signal = record.signal {
			fields.append(Log.Record.CanonicalLogLineField(key: "signal", value: signal.identifier))
		}

		if let category = record.category {
			fields.append(Log.Record.CanonicalLogLineField(key: "category", value: category.identifier))
		}

		if !record.message.isEmpty {
			fields.append(Log.Record.CanonicalLogLineField(key: "message", value: record.message))
		}

		fields.append(
			contentsOf: record.payload.map { payload in
				Log.Record.CanonicalLogLineField(
					key: payload.key,
					value: payload.value.formatted(.logPayloadValue)
				)
			}
		)

		return fields
	}
}

// MARK: Log.Record.CanonicalLogLineField

extension Log.Record {
	struct CanonicalLogLineField {
		let key: String
		let value: String

		func formatted() -> String {
			"\(Log.Record.KeyValueFieldFormatter.canonicalKey(self.key))=\(Log.Record.KeyValueFieldFormatter.value(self.value))"
		}
	}
}
