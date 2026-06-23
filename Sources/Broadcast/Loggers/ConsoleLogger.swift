#if canImport(OSLog)
	import OSLog
#endif

/// A destination that writes Broadcast logs to the platform console.
///
/// On Apple platforms this is backed by the unified logging system (OSLog), so logs
/// appear in Console.app, Xcode, or OSLog collection tools. On platforms without
/// OSLog (e.g. Linux) it falls back to writing formatted lines to standard output.
/// Apps should usually initialize it with their own subsystem and category so logs
/// can be inspected separately from Broadcast internals. Broadcast writes rendered
/// log values with public privacy, so do not send secrets, tokens, or sensitive user
/// data to this destination.
public struct ConsoleLogger: LoggingDestination {
	#if canImport(OSLog)
		private let logger: Logger
	#else
		private let subsystem: String
		private let category: String
	#endif

	/// Creates a console-backed destination.
	///
	/// Use your app or framework bundle identifier as the subsystem and a stable area
	/// name as the category.
	public init(subsystem: String, category: String) {
		#if canImport(OSLog)
			self.logger = Logger(subsystem: subsystem, category: category)
		#else
			self.subsystem = subsystem
			self.category = category
		#endif
	}

	public func log(_ record: Log.Record) {
		let text = self.recordFormatter.format(record)
		#if canImport(OSLog)
			self.logger.log(level: record.level.osLogType, "\(text, privacy: .public)")
		#else
			print("[\(self.subsystem)] [\(self.category)] \(text)")
		#endif
	}
}

#if canImport(OSLog)
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
#endif
