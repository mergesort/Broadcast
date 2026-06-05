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
			"\(Self.canonicalKey(key))=\(Self.canonicalValue(value))"
		}
	}
}

// MARK: Private

private extension Log.Record.CanonicalLogLineField {
	static func canonicalKey(_ key: String) -> String {
		let scalars = key.unicodeScalars.map { scalar in
			if Self.isCanonicalKeyScalar(scalar) {
				String(scalar)
			} else {
				"_"
			}
		}
		.joined()

		if scalars.isEmpty {
			return "payload"
		} else {
			return scalars
		}
	}

	static func canonicalValue(_ value: String) -> String {
		if value.isEmpty {
			return "\"\""
		}

		if value.unicodeScalars.allSatisfy(Self.isBareValueScalar) {
			return value
		}

		let escaped = value
			.replacingOccurrences(of: "\\", with: "\\\\")
			.replacingOccurrences(of: "\"", with: "\\\"")

		return "\"\(escaped)\""
	}

	static func isCanonicalKeyScalar(_ scalar: Unicode.Scalar) -> Bool {
		switch scalar.value {
		case 48...57, 65...90, 97...122: true
		case 45, 46, 95: true
		default: false
		}
	}

	static func isBareValueScalar(_ scalar: Unicode.Scalar) -> Bool {
		if scalar.properties.isWhitespace {
			return false
		}

		return switch scalar {
		case "\"", "=": false
		default: true
		}
	}
}
