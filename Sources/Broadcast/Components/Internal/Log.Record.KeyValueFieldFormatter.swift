import Foundation

extension Log.Record {
	enum KeyValueFieldFormatter {
		static func canonicalKey(_ key: String, defaultKey: String = "payload") -> String {
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

		static func value(_ value: String, escapingControlCharacters: Bool = false) -> String {
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
