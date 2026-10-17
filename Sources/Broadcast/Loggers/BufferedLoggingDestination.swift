/// A destination that keeps records so they can be exported later.
///
/// Use a buffered destination for support screens, bug report attachments, AI
/// debugging exports, and tests that need to inspect what your app logged.
/// Destinations that only write elsewhere, such as the system console, should
/// conform to ``LoggingDestination`` directly.
public protocol BufferedLoggingDestination: LoggingDestination {
	/// The formatter used when exporting buffered records as text.
	///
	/// Provide a custom formatter to change the output of `logs()` and `logs(count:)`.
	var recordFormatter: Log.Record.Formatter { get }

	/// Returns the original records currently buffered by this destination.
	func records() -> [Log.Record]

	/// Returns the currently buffered records as readable export text.
	func logs() -> String
}

public extension BufferedLoggingDestination {
	/// The default formatter used for buffered text exports.
	var recordFormatter: Log.Record.Formatter {
		.default
	}

	/// Returns the currently buffered records as readable export text.
	func logs() -> String {
		self.records()
			.map({ self.recordFormatter.format($0) })
			.joined(separator: "\n")
			.trimmingCharacters(in: .newlines)
	}

	/// Returns all buffered logs or the most recent `count` entries.
	func logs(count: Int? = nil) -> String {
		if let count {
			self.records()
				.sorted(by: { $0.timestamp.date > $1.timestamp.date })
				.prefix(count)
				.map({ self.recordFormatter.format($0) })
				.joined(separator: "\n")
				.trimmingCharacters(in: .newlines)
		} else {
			self.logs()
		}
	}
}
