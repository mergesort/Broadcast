import Foundation

public extension Log.Record.FormatStyle {
	func format(_ value: Log.Record) -> String {
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
