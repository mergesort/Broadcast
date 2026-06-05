import Broadcast
import OSLog

struct DemoConsoleLogger: LoggingDestination {
	private let logger: Logger

	init(subsystem: String, category: String) {
		self.logger = Logger(subsystem: subsystem, category: category)
	}

	var recordFormatter: Log.Record.Formatter {
		.canonicalLogLine
	}

	func log(_ record: Log.Record) {
		let text = self.recordFormatter.format(record)
		self.logger.log(level: record.level.osLogType, "\(text, privacy: .public)")
	}
}

// MARK: Log.Level

private extension Log.Level {
	var osLogType: OSLogType {
		switch self {
		case .debug: .debug
		case .info: .info
		case .warn: .default
		case .error: .error
		case .fault: .fault
		}
	}
}
