import Broadcast

internal final class CapturingLoggingDestination: LoggingDestination {
	private(set) var records: [Log.Record] = []
	private(set) var debugLogs: [String] = []
	private(set) var infoLogs: [String] = []
	private(set) var warnLogs: [String] = []
	private(set) var errorLogs: [String] = []
	private(set) var faultLogs: [String] = []

	func log(_ record: Log.Record) {
		self.records.append(record)
		let text = self.recordFormatter.format(record)

		switch record.level {
		case .debug: self.debugLogs.append(text)
		case .info: self.infoLogs.append(text)
		case .warn: self.warnLogs.append(text)
		case .error: self.errorLogs.append(text)
		case .fault: self.faultLogs.append(text)
		}
	}
}
