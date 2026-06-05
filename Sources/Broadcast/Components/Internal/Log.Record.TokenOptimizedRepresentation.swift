import Foundation

extension Log.Record {
	struct TokenOptimizedRepresentation {
		let fields: [KeyValuePair]

		init(record: Log.Record) {
			self.fields = Self.fields(for: record)
		}

		func formatted() -> String {
			self.fields
				.map({ $0.formatted(.tokenOptimized) })
				.joined(separator: " ")
		}
	}
}

// MARK: Private

private extension Log.Record.TokenOptimizedRepresentation {
	static func fields(for record: Log.Record) -> [Log.Record.KeyValuePair] {
		var fields = [
			Log.Record.KeyValuePair(key: "t", value: Self.millisecondsSince1970(for: record.timestamp.date)),
			Log.Record.KeyValuePair(key: "l", value: record.level.rawValue)
		]

		if let signal = record.signal {
			fields.append(Log.Record.KeyValuePair(key: "s", value: signal.identifier))
		}

		if let category = record.category {
			fields.append(Log.Record.KeyValuePair(key: "c", value: category.identifier))
		}

		if !record.message.isEmpty {
			fields.append(Log.Record.KeyValuePair(key: "m", value: record.message))
		}

		fields.append(
			contentsOf: record.payload.map { payload in
				Log.Record.KeyValuePair(
					key: "p.\(payload.key.isEmpty ? "payload" : payload.key)",
					value: payload.value.formatted(.tokenOptimizedPayloadValue)
				)
			}
		)

		return fields
	}
}

// MARK: Internal

extension Log.Record.TokenOptimizedRepresentation {
	static func millisecondsSince1970(for date: Date) -> String {
		let milliseconds = (date.timeIntervalSince1970 * 1000).rounded(.toNearestOrAwayFromZero)

		return String(Int64(milliseconds))
	}
}

// MARK: Log.Payload.Value.TokenOptimizedFormatStyle

extension Log.Payload.Value {
	struct TokenOptimizedFormatStyle: Foundation.FormatStyle {
		init() {}

		func format(_ value: Log.Payload.Value) -> String {
			switch value {
			case .string(let string): return string ?? "nil"
			case .bool(let bool): return bool ? "true" : "false"
			case .int(let int): return String(describing: int)
			case .uuid(let uuid): return uuid?.uuidString ?? "nil"
			case .url(let url): return url?.absoluteString ?? "nil"
			case .date(let date):
				if let date {
					return Log.Record.TokenOptimizedRepresentation.millisecondsSince1970(for: date)
				} else {
					return "nil"
				}
			case .error(let error): return String(describing: error)
			case .duration(let seconds):
				let milliseconds = (seconds * 1000).rounded(.toNearestOrAwayFromZero)

				return "\(Int64(milliseconds))ms"
			}
		}
	}
}

extension FormatStyle where Self == Log.Payload.Value.TokenOptimizedFormatStyle {
	static var tokenOptimizedPayloadValue: Self {
		Self()
	}
}
