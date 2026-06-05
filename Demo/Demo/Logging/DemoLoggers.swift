import Broadcast

@MainActor
struct DemoLoggers {
	let liveLogger: SessionLogger
	let metricsLogger: SessionLogger
	let auditLogger: PersistentAuditLogger
	let operationsLog: Log
	let metricsLog: Log
	let auditLog: Log

	init() {
		let consoleLogger = ConsoleLogger(subsystem: "com.mergesort.BroadcastDemo", category: "operations")
		let liveLogger = SessionLogger()
		let metricsLogger = SessionLogger(timestampFormatStyle: .timestamp)
		let auditLogger = PersistentAuditLogger(limit: 5_000)

		self.liveLogger = liveLogger
		self.metricsLogger = metricsLogger
		self.auditLogger = auditLogger
		self.operationsLog = Log(destinations: [consoleLogger, liveLogger])
		self.metricsLog = self.operationsLog.combined(with: metricsLogger)
		self.auditLog = Log(destinations: [auditLogger])
	}

	func bufferedLogger(for feed: LogFeed) -> any BufferedLoggingDestination {
		switch feed {
		case .live: self.liveLogger
		case .metrics: self.metricsLogger
		case .audit: self.auditLogger
		}
	}

	func removeAll() async {
		self.liveLogger.removeAll()
		self.metricsLogger.removeAll()
		await self.auditLogger.removeAll()
	}
}
