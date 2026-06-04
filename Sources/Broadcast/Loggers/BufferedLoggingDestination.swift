/// A logging destination that can export the text it has captured.
///
/// This capability can be used for support flows, diagnostics exports, or tests that need to
/// inspect emitted logs. Destinations that only write elsewhere, such as the system
/// console, should conform to ``LoggingDestination`` directly.
public protocol BufferedLoggingDestination: LoggingDestination {
	/// Returns the destination's currently buffered records.
	func records() -> [Log.Record]

	/// Returns the destination's currently buffered logs as exportable text.
	func logs() -> String
}

public extension BufferedLoggingDestination {
	/// Returns the destination's currently buffered records as exportable text.
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
