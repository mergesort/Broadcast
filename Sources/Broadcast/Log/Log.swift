/// The API your app calls to write logs.
///
/// A ``Log`` owns one or more destinations. Every `log.debug`, `log.info`, or
/// `log.error` call is sent to each destination, so your app gets one simple API
/// while destinations decide where records go and how they are formatted.
public struct Log {
	/// The destinations that receive every log call.
	///
	/// Use multiple destinations when the same event should go to the console, an
	/// in-memory support log, a persistent store, or a custom destination you build.
	public let destinations: [any LoggingDestination]

	/// Creates a log that writes to each destination in order.
	public init(destinations: [any LoggingDestination]) {
		self.destinations = destinations
	}

	/// Logs one or more values.
	///
	/// Prefer this variadic form for multiple values, such as `log.debug("Created", "Reminder", 3)`.
	/// Passing an array, such as `log.debug([a, b, c])`, intentionally logs that array
	/// as one value, matching the way Swift's `print` treats array arguments.
	public func debug(_ values: Any...) {
		self.performLoggingOperation({ $0.debug(values) })
	}

	public func debug() {
		self.performLoggingOperation({ $0.debug() })
	}

	/// Logs one or more values.
	///
	/// Prefer this variadic form for multiple values, such as `log.info("Created", "Reminder", 3)`.
	/// Passing an array, such as `log.info([a, b, c])`, intentionally logs that array
	/// as one value, matching the way Swift's `print` treats array arguments.
	public func info(_ values: Any...) {
		self.performLoggingOperation({ $0.info(values) })
	}

	public func info() {
		self.performLoggingOperation({ $0.info() })
	}

	/// Logs one or more values.
	///
	/// Prefer this variadic form for multiple values, such as `log.warn("Created", "Reminder", 3)`.
	/// Passing an array, such as `log.warn([a, b, c])`, intentionally logs that array
	/// as one value, matching the way Swift's `print` treats array arguments.
	public func warn(_ values: Any...) {
		self.performLoggingOperation({ $0.warn(values) })
	}

	public func warn() {
		self.performLoggingOperation({ $0.warn() })
	}

	/// Logs one or more values.
	///
	/// Prefer this variadic form for multiple values, such as `log.error("Created", "Reminder", 3)`.
	/// Passing an array, such as `log.error([a, b, c])`, intentionally logs that array
	/// as one value, matching the way Swift's `print` treats array arguments.
	public func error(_ values: Any...) {
		self.performLoggingOperation({ $0.error(values) })
	}

	public func error() {
		self.performLoggingOperation({ $0.error() })
	}

	/// Logs one or more values.
	///
	/// Prefer this variadic form for multiple values, such as `log.fault("Created", "Reminder", 3)`.
	/// Passing an array, such as `log.fault([a, b, c])`, intentionally logs that array
	/// as one value, matching the way Swift's `print` treats array arguments.
	public func fault(_ values: Any...) {
		self.performLoggingOperation({ $0.fault(values) })
	}

	public func fault() {
		self.performLoggingOperation({ $0.fault() })
	}
}

public extension Log {
	/// Broadcast's shared in-memory support log for the current process.
	///
	/// Prefer creating and injecting your own ``SessionLogger`` when you need explicit
	/// lifetime control, deterministic tests, or multiple independently exported buffers.
	static let sessionLogger = SessionLogger()

	#if canImport(OSLog)
	/// Broadcast's shared console destination.
	///
	/// Prefer creating your own ``ConsoleLogger`` with your app's subsystem and category
	/// for production integrations.
	static let consoleLogger = ConsoleLogger(subsystem: "com.mergesort.broadcast", category: "logs")
	#endif

	/// A convenience log that writes to Broadcast's default console and session destinations.
	///
	/// This is useful for quick integration or examples. Apps that need support-log
	/// export, privacy-specific routing, or dependency injection should construct
	/// their own ``Log``.
	///
	/// ``ConsoleLogger`` is only included on Apple platforms where OSLog is available;
	/// elsewhere the default log writes to the ``SessionLogger`` alone.
	static let `default` = Log(
		destinations: {
			#if canImport(OSLog)
			return [Log.consoleLogger, Log.sessionLogger]
			#else
			return [Log.sessionLogger]
			#endif
		}()
	)
}

extension Log {
	func performLoggingOperation(_ operation: (any LoggingDestination) -> Void) {
		for destination in self.destinations {
			operation(destination)
		}
	}
}
