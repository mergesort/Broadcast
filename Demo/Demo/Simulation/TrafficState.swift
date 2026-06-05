import Broadcast

struct TrafficState {
	var processedRequests: Int
	var queueDepth: Int
	var activeWorkers: Int
	var averageLatencyMS: Int
	var errorBudget: Int
	var isIncidentMode: Bool

	static let initial = Self(
		processedRequests: 42,
		queueDepth: 8,
		activeWorkers: 3,
		averageLatencyMS: 126,
		errorBudget: 96,
		isIncidentMode: false
	)

	var modeLabel: String {
		let prefix = "Status: "
		let suffix = self.isIncidentMode ? "Incident response active" : "Normal traffic"

		return prefix + suffix
	}

	var errorRatePercent: Int {
		100 - self.errorBudget
	}

	func payload(additionalPayload: [Log.Payload] = []) -> [Log.Payload] {
		[
			.processedRequests(self.processedRequests),
			.queueDepth(self.queueDepth),
			.workers(self.activeWorkers),
			.latency(milliseconds: self.averageLatencyMS),
			.errorBudget(self.errorBudget),
			.incidentMode(self.isIncidentMode)
		] + additionalPayload
	}
}
