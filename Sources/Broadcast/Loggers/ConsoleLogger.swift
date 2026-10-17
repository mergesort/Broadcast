#if canImport(OSLog)
import OSLog

/// A destination that writes Broadcast logs to Apple's unified logging system.
///
/// Use ``ConsoleLogger`` when you want logs to appear in Console.app, Xcode, or OSLog
/// collection tools. Apps should usually initialize it with their own subsystem and
/// category so logs can be inspected separately from Broadcast internals.
///
/// Signals, record categories, messages, and payloads use public privacy by default; choose
/// ``Privacy/private`` to mark all of these values private in unified logging.
///
/// Console output uses a fixed unified logging template rather than the record's
/// text formatter. The logging system supplies the severity and emission timestamp,
/// while payloads are still rendered as text.
public struct ConsoleLogger: LoggingDestination {
	private let logger: Logger
	private let privacy: Privacy

	/// Creates an OSLog-backed destination.
	///
	/// Use your app or framework bundle identifier as the subsystem and a stable area
	/// name as the category. Privacy defaults to public to preserve existing output.
	public init(subsystem: String, category: String, privacy: Privacy = .public) {
		self.logger = Logger(subsystem: subsystem, category: category)
		self.privacy = privacy
	}

	public func log(_ record: Log.Record) {
		// OSLog requires compile-time privacy annotations at each logging call.
		switch self.privacy {
		case .public:
			self.logger.log(
				level: record.level.osLogType,
				"""
				[\(record.signal?.identifier ?? "-", privacy: .public) | \
				\(record.category?.identifier ?? "-", privacy: .public)] \
				\(record.message, privacy: .public) \
				payload=[\(record.payload.consoleLogText, privacy: .public)]
				"""
			)
		case .private:
			self.logger.log(
				level: record.level.osLogType,
				"""
				[\(record.signal?.identifier ?? "-", privacy: .private) | \
				\(record.category?.identifier ?? "-", privacy: .private)] \
				\(record.message, privacy: .private) \
				payload=[\(record.payload.consoleLogText, privacy: .private)]
				"""
			)
		}
	}
}

// MARK: ConsoleLogger.Privacy

public extension ConsoleLogger {
	/// The unified logging privacy applied to all interpolated record fields.
	/// This setting does not redact records sent to other Broadcast destinations.
	enum Privacy: Sendable {
		/// Makes interpolated record fields visible in unified logging.
		case `public`

		/// Marks interpolated record fields private using the system's redaction policy.
		case `private`
	}
}

// MARK: [Log.Payload]

private extension [Log.Payload] {
	var consoleLogText: String {
		self
			.map({ $0.formatted(.logPayload) })
			.joined(separator: ", ")
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
#endif
