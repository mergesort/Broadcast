import Broadcast
import Foundation

enum LogExport {
	static func text(for records: [Log.Record], formatter: Log.Record.Formatter) -> String {
		records
			.sorted(by: { $0.timestamp.date < $1.timestamp.date })
			.map({ formatter.format($0) })
			.joined(separator: "\n")
			.trimmingCharacters(in: .newlines)
	}
}
