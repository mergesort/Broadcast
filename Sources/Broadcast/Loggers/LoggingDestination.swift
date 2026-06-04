/// A write-only logging sink.
///
/// ``Log.Record`` is Broadcast's canonical log event model. Destination
/// requirements accept records so custom destinations can inspect level, timestamp,
/// signal, category, message, and payload without re-parsing formatted strings.
/// Consumer call-sites should usually use the ergonomic ``Log`` APIs instead of
/// constructing records manually.
public protocol LoggingDestination {
	/// Supplies dates for records created by this destination's convenience methods.
	///
	/// Destinations can override this for deterministic tests or custom time sources.
	var dateProvider: Log.DateProvider { get }

	/// The type-erased formatter this destination uses for log records.
	///
	/// Custom destinations can override this with
	/// `Log.Record.Formatter(.customRecordStyle)` to change how records are rendered
	/// while preserving the same ergonomic ``Log`` call-sites.
	var recordFormatter: Log.Record.Formatter { get }

	/// Handles a canonical Broadcast log record.
	func log(_ record: Log.Record)
}

public extension LoggingDestination {
	/// Logs one or more values at debug level.
	func debug(_ values: Any...) {
		self.debug(values)
	}

	func debug(_ values: [Any]) {
		self.log(level: .debug, values: values)
	}

	/// Writes a print-like blank line.
	func debug() {
		self.debug([])
	}

	func debug(_ signal: Log.Signal, _ message: String, category: Log.Category, payload: [Log.Payload] = []) {
		self.log(level: .debug, signal: signal, message: message, category: category, payload: payload)
	}

	/// Logs one or more values at info level.
	func info(_ values: Any...) {
		self.info(values)
	}

	func info(_ values: [Any]) {
		self.log(level: .info, values: values)
	}

	/// Writes a print-like blank line.
	func info() {
		self.info([])
	}

	func info(_ signal: Log.Signal, _ message: String, category: Log.Category, payload: [Log.Payload] = []) {
		self.log(level: .info, signal: signal, message: message, category: category, payload: payload)
	}

	/// Logs one or more values at warning level.
	func warn(_ values: Any...) {
		self.warn(values)
	}

	func warn(_ values: [Any]) {
		self.log(level: .warn, values: values)
	}

	/// Writes a print-like blank line.
	func warn() {
		self.warn([])
	}

	func warn(_ signal: Log.Signal, _ message: String, category: Log.Category, payload: [Log.Payload] = []) {
		self.log(level: .warn, signal: signal, message: message, category: category, payload: payload)
	}

	/// Logs one or more values at error level.
	func error(_ values: Any...) {
		self.error(values)
	}

	func error(_ values: [Any]) {
		self.log(level: .error, values: values)
	}

	/// Writes a print-like blank line.
	func error() {
		self.error([])
	}

	func error(_ signal: Log.Signal, _ message: String, category: Log.Category, payload: [Log.Payload] = []) {
		self.log(level: .error, signal: signal, message: message, category: category, payload: payload)
	}

	/// Logs one or more values at fault level.
	func fault(_ values: Any...) {
		self.fault(values)
	}

	func fault(_ values: [Any]) {
		self.log(level: .fault, values: values)
	}

	/// Writes a print-like blank line.
	func fault() {
		self.fault([])
	}

	func fault(_ signal: Log.Signal, _ message: String, category: Log.Category, payload: [Log.Payload] = []) {
		self.log(level: .fault, signal: signal, message: message, category: category, payload: payload)
	}
}

public extension LoggingDestination {
	/// The default date provider used when convenience methods create records.
	var dateProvider: Log.DateProvider {
		.default
	}

	/// The default formatter used when this destination renders records.
	var recordFormatter: Log.Record.Formatter {
		.default
	}

	/// Formats raw plain-log arguments using Broadcast's default argument rendering.
	///
	/// Use this from custom ``LoggingDestination`` implementations when they need to
	/// mirror Broadcast's plain argument rendering. Keeping this conversion centralized
	/// preserves Swift's `print`-like behavior: multiple variadic arguments are
	/// rendered independently, and an array passed as a single argument is rendered as
	/// that one array value.
	static func formattedArgumentValues(_ values: [Any]) -> [String] {
		values.map({ String(describing: $0) })
	}
}

// MARK: Private

private extension LoggingDestination {
	func log(level: Log.Level, values: [Any]) {
		let message = Self.formattedArgumentValues(values)
			.joined(separator: ", ")

		self.log(
			Log.Record(
				timestamp: Log.Timestamp(self.dateProvider.date),
				level: level,
				message: message
			)
		)
	}

	func log(level: Log.Level, signal: Log.Signal, message: String, category: Log.Category, payload: [Log.Payload]) {
		self.log(
			Log.Record(
				timestamp: Log.Timestamp(self.dateProvider.date),
				level: level,
				signal: signal,
				message: message,
				category: category,
				payload: payload
			)
		)
	}
}
