import Foundation

extension Log.Record {
	struct CanonicalLogLineRepresentation {
		let timestamp: String
		let fields: [KeyValuePair]

		init(record: Log.Record, timestampFormatStyle: Log.Timestamp.FormatStyle) {
			self.timestamp = record.timestamp.formatted(timestampFormatStyle)
			self.fields = Self.fields(for: record)
		}

		func formatted() -> String {
			let fields = self.fields
				.map({ $0.formatted(.normalized) })
				.joined(separator: " ")

			return "[\(self.timestamp)] canonical-log-line \(fields)"
		}
	}
}

// MARK: Private

private extension Log.Record.CanonicalLogLineRepresentation {
	static func fields(for record: Log.Record) -> [Log.Record.KeyValuePair] {
		var fields = [
			Log.Record.KeyValuePair(key: "level", value: record.level.rawValue)
		]

		if let signal = record.signal {
			fields.append(Log.Record.KeyValuePair(key: "signal", value: signal.identifier))
		}

		if let category = record.category {
			fields.append(Log.Record.KeyValuePair(key: "category", value: category.identifier))
		}

		if !record.message.isEmpty {
			fields.append(Log.Record.KeyValuePair(key: "message", value: record.message))
		}

		fields.append(
			contentsOf: record.payload.map { payload in
				Log.Record.KeyValuePair(
					key: payload.key,
					value: payload.value.formatted(.logPayloadValue)
				)
			}
		)

		return fields
	}
}
