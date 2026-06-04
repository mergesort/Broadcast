import OSLog

/// A destination that writes Broadcast logs to Apple's unified logging system.
///
/// Use ``ConsoleLogger`` when you want logs to appear in Console.app, Xcode, or OSLog
/// collection tools. Apps should usually initialize it with their own subsystem and
/// category so logs can be filtered separately from Broadcast internals. Broadcast
/// writes rendered log values with public privacy, so do not send secrets, tokens, or
/// sensitive user data to this destination.
public struct ConsoleLogger: LoggingDestination {
	private let logger: Logger

	/// Creates an OSLog-backed destination.
	///
	/// Use your app or framework bundle identifier as the subsystem and a stable area
	/// name as the category.
	public init(subsystem: String, category: String) {
		self.logger = Logger(subsystem: subsystem, category: category)
	}

	public func log(_ record: Log.Record) {
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
