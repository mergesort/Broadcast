import Broadcast
import Foundation

enum LogExport {
	enum Format: String, CaseIterable, Identifiable {
		case standard
		case canonicalLogLine
		case json

		var id: String {
			self.rawValue
		}

		var title: String {
			switch self {
			case .standard: "Default"
			case .canonicalLogLine: "Canonical Log Line"
			case .json: "JSON"
			}
		}

		var systemImage: String {
			switch self {
			case .standard: "text.alignleft"
			case .canonicalLogLine: "list.bullet.rectangle"
			case .json: "curlybraces"
			}
		}

		var formatter: Log.Record.Formatter {
			switch self {
			case .standard: .default
			case .canonicalLogLine: .canonicalLogLine
			case .json: .json
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
