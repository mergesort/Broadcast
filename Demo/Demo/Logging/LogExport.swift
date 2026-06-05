import Broadcast
import Foundation

enum LogExport {
	enum Format: String, CaseIterable, Identifiable {
		case canonicalLogLine
		case `default`
		case json
		case tokenOptimized

		static let menuCases: [Self] = [
			.default,
			.json,
			.tokenOptimized,
			.canonicalLogLine
		]

		var id: String {
			self.rawValue
		}

		var title: String {
			switch self {
			case .canonicalLogLine: "Canonical Log Line"
			case .default: "Default Format"
			case .json: "JSON"
			case .tokenOptimized: "Token Optimized"
			}
		}

		var systemImage: String {
			switch self {
			case .canonicalLogLine: "list.bullet.rectangle"
			case .default: "text.alignleft"
			case .json: "curlybraces"
			case .tokenOptimized: "laptopcomputer"
			}
		}

		var formatter: Log.Record.Formatter {
			switch self {
			case .canonicalLogLine: .canonicalLogLine
			case .default: .default
			case .json: .json
			case .tokenOptimized: .tokenOptimized
			}
		}
	}
}

extension LogExport.Format {
	func text(for records: [Log.Record]) -> String {
		records
			.sorted(by: { $0.timestamp.date < $1.timestamp.date })
			.map({ self.formatter.format($0) })
			.joined(separator: "\n")
			.trimmingCharacters(in: .newlines)
	}
}
