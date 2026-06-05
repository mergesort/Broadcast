import Foundation

extension Log.Record {
	struct KeyValueFormatStyle: Foundation.FormatStyle, Sendable {
		private let mode: Mode

		init(mode: Mode) {
			self.mode = mode
		}

		func format(_ value: Log.Record.KeyValuePair) -> String {
			switch self.mode {
			case .raw:
				"\(value.key)=\(value.value)"
			case .normalized:
				"\(Self.normalizedKey(value.key))=\(Self.normalizedValue(value.value))"
			case .tokenOptimized:
				"\(Self.normalizedKey(value.key))=\(Self.normalizedValue(value.value, escapingControlCharacters: true))"
			}
		}
	}
}

// MARK: FormatStyle

extension FormatStyle where Self == Log.Record.KeyValueFormatStyle {
	static var raw: Self {
		Self(mode: .raw)
	}

	static var normalized: Self {
		Self(mode: .normalized)
	}

	static var tokenOptimized: Self {
		Self(mode: .tokenOptimized)
	}
}

// MARK: Log.Record.KeyValueFormatStyle.Mode

extension Log.Record.KeyValueFormatStyle {
	enum Mode: Codable, Hashable, Sendable {
		case raw
		case normalized
		case tokenOptimized
	}
}

// MARK: Private

private extension Log.Record.KeyValueFormatStyle {
	static func normalizedKey(_ key: String, defaultKey: String = "payload") -> String {
		let scalars = key.unicodeScalars.map { scalar in
			if scalar.isLogLineKeyScalar {
				String(scalar)
			} else {
				"_"
			}
		}
		.joined()

		if scalars.isEmpty {
			return defaultKey
		} else {
			return scalars
		}
	}

	static func normalizedValue(_ value: String, escapingControlCharacters: Bool = false) -> String {
		if value.isEmpty {
			return "\"\""
		}

		if value.unicodeScalars.allSatisfy(\.isBareLogLineValueScalar) {
			return value
		}

		var escaped = value
			.replacingOccurrences(of: "\\", with: "\\\\")
			.replacingOccurrences(of: "\"", with: "\\\"")

		if escapingControlCharacters {
			escaped = escaped
				.replacingOccurrences(of: "\n", with: "\\n")
				.replacingOccurrences(of: "\r", with: "\\r")
				.replacingOccurrences(of: "\t", with: "\\t")
		}

		return "\"\(escaped)\""
	}
}

// MARK: Unicode.Scalar

private extension Unicode.Scalar {
	var isLogLineKeyScalar: Bool {
		switch self.value {
		case 48...57, 65...90, 97...122: true
		case 45, 46, 95: true
		default: false
		}
	}

	var isBareLogLineValueScalar: Bool {
		if self.properties.isWhitespace {
			return false
		}

		return switch self {
		case "\"", "=": false
		default: true
		}
	}
}
