import Foundation

extension Log.Record {
	struct TokenOptimizedRepresentation {
		let fields: [TokenOptimizedField]

		init(record: Log.Record) {
			self.fields = Self.fields(for: record)
		}

		func formatted() -> String {
			self.fields
				.map({ $0.formatted() })
				.joined(separator: " ")
		}
	}
}

// MARK: Private

private extension Log.Record.TokenOptimizedRepresentation {
	static func fields(for record: Log.Record) -> [Log.Record.TokenOptimizedField] {
		var fields = [
			Log.Record.TokenOptimizedField(key: "t", value: Self.millisecondsSince1970(for: record.timestamp.date)),
			Log.Record.TokenOptimizedField(key: "l", value: record.level.rawValue)
		]

		if let signal = record.signal {
			fields.append(Log.Record.TokenOptimizedField(key: "s", value: signal.identifier))
		}

		if let category = record.category {
			fields.append(Log.Record.TokenOptimizedField(key: "c", value: category.identifier))
		}

		if !record.message.isEmpty {
			fields.append(Log.Record.TokenOptimizedField(key: "m", value: record.message))
		}

		fields.append(
			contentsOf: record.payload.map { payload in
				Log.Record.TokenOptimizedField(
					key: "p.\(Log.Record.KeyValueFieldFormatter.canonicalKey(payload.key))",
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

// MARK: Log.Record.TokenOptimizedField

extension Log.Record {
	struct TokenOptimizedField {
		let key: String
		let value: String

		func formatted() -> String {
			"\(self.key)=\(Log.Record.KeyValueFieldFormatter.value(self.value, escapingControlCharacters: true))"
		}
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
