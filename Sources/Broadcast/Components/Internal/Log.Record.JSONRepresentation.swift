import Foundation

extension Log.Record {
	struct JSONRepresentation: Encodable {
		let timestamp: String
		let level: String
		let signal: String?
		let category: String?
		let message: String?
		let payload: [String: JSONPayloadValue]?

		init(record: Log.Record, timestampFormatStyle: Log.Timestamp.FormatStyle) {
			self.timestamp = record.timestamp.formatted(timestampFormatStyle)
			self.level = record.level.rawValue
			self.signal = record.signal?.identifier
			self.category = record.category?.identifier
			self.message = record.message.isEmpty ? nil : record.message
			self.payload = Self.payloadValues(for: record)
		}
	}
}

// MARK: Private

private extension Log.Record.JSONRepresentation {
	static func payloadValues(for record: Log.Record) -> [String: Log.Record.JSONPayloadValue]? {
		if record.payload.isEmpty {
			return nil
		}

		var payloadValues: [String: Log.Record.JSONPayloadValue] = [:]

		for payload in record.payload {
			payloadValues[payload.key] = Log.Record.JSONPayloadValue(payload.value)
		}

		return payloadValues
	}
}

// MARK: Log.Record.JSONPayloadValue

extension Log.Record {
	struct JSONPayloadValue: Encodable {
		let value: Log.Payload.Value

		init(_ value: Log.Payload.Value) {
			self.value = value
		}

		func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()

			switch self.value {
			case .string(let string):
				if let string {
					try container.encode(string)
				} else {
					try container.encodeNil()
				}
			case .bool(let bool):
				try container.encode(bool)
			case .int(let int):
				try container.encode(int)
			case .uuid(let uuid):
				if let uuid {
					try container.encode(uuid.uuidString)
				} else {
					try container.encodeNil()
				}
			case .url(let url):
				if let url {
					try container.encode(url.absoluteString)
				} else {
					try container.encodeNil()
				}
			case .date(let date):
				if let date {
					try container.encode(date.formatted(.iso8601))
				} else {
					try container.encodeNil()
				}
			case .error(let error):
				try container.encode(error)
			case .duration(let seconds):
				try container.encode(seconds)
			}
		}
	}
}
