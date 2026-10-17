#if SwiftLogging
import Foundation
import Logging

/// A destination that forwards Broadcast records into swift-log.
///
/// Add ``SwiftLogDestination`` to a ``Log`` when Broadcast should remain the
/// call-site API, but the app or server also wants its records delivered to the
/// process's configured swift-log backend.
///
/// This type is available when the package is built with the `SwiftLogging`
/// package trait.
public final class SwiftLogDestination: LoggingDestination {
	private let logger: Logger

	/// Creates a destination that uses a swift-log `Logger` with the provided label.
	public init(label: String, logLevel: Logger.Level = .trace) {
		var logger = Logger(label: label)
		logger.logLevel = logLevel
		self.logger = logger
	}

	/// Creates a destination that forwards records to an existing swift-log `Logger`.
	public init(logger: Logger) {
		self.logger = logger
	}

	public func log(_ record: Log.Record) {
		self.logger.log(
			level: record.level.swiftLogLevel,
			"\(record.message)",
			metadata: record.swiftLogMetadata
		)
	}
}

// MARK: Log.Level

private extension Log.Level {
	var swiftLogLevel: Logger.Level {
		switch self {
		case .debug: .debug
		case .info: .info
		case .warn: .warning
		case .error: .error
		case .fault: .critical
		}
	}
}

// MARK: Log.Record

private extension Log.Record {
	var swiftLogMetadata: Logger.Metadata {
		var metadata: Logger.Metadata = [
			"broadcast.id": "\(self.id.uuidString)",
			"broadcast.timestamp": "\(self.timestamp.formatted(.default))"
		]

		if let signal {
			metadata["broadcast.signal"] = "\(signal.identifier)"
		}

		if let category {
			metadata["broadcast.category"] = "\(category.identifier)"
		}

		for payload in self.payload {
			metadata["payload.\(payload.key)"] = "\(payload.value.formatted(.logPayloadValue))"
		}

		return metadata
	}
}
#endif
