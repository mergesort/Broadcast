import Foundation

public extension Log {
	/// Logs a structured debug entry.
	///
	/// Use structured debug logs for verbose diagnostics that benefit from category,
	/// signal, and typed payload context. Destinations own final ``Log/Record`` formatting.
	func debug(_ signal: Log.Signal, _ message: String, category: Log.Category, payload: [Log.Payload] = []) {
		self.performLoggingOperation({ $0.debug(signal, message, category: category, payload: payload) })
	}

	/// Logs a structured informational entry.
	///
	/// Use structured info logs for durable, support-relevant milestones and outcomes.
	/// Destinations own final ``Log/Record`` formatting.
	func info(_ signal: Log.Signal, _ message: String, category: Log.Category, payload: [Log.Payload] = []) {
		self.performLoggingOperation({ $0.info(signal, message, category: category, payload: payload) })
	}

	/// Logs a structured warning entry.
	///
	/// Use structured warnings for recoverable problems that may explain degraded
	/// behavior without representing a hard failure. Destinations own final ``Log/Record`` formatting.
	func warn(_ signal: Log.Signal, _ message: String, category: Log.Category, payload: [Log.Payload] = []) {
		self.performLoggingOperation({ $0.warn(signal, message, category: category, payload: payload) })
	}

	/// Logs a structured error entry.
	///
	/// Put the underlying error and relevant identifiers in payloads instead of
	/// interpolating them into the message, so diagnostics stay parseable.
	/// Destinations own final ``Log/Record`` formatting.
	func error(_ signal: Log.Signal, _ message: String, category: Log.Category, payload: [Log.Payload] = []) {
		self.performLoggingOperation({ $0.error(signal, message, category: category, payload: payload) })
	}

	/// Logs a structured fault entry.
	///
	/// Use faults for severe conditions that indicate data loss, corruption, or an
	/// unrecoverable subsystem failure. Destinations own final ``Log/Record`` formatting.
	func fault(_ signal: Log.Signal, _ message: String, category: Log.Category, payload: [Log.Payload] = []) {
		self.performLoggingOperation({ $0.fault(signal, message, category: category, payload: payload) })
	}
}
