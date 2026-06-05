import Broadcast
import Foundation

extension Log.Payload {
	static func result(_ value: String) -> Self {
		Self(key: "result", value: value)
	}

	static func requestID(_ value: UUID) -> Self {
		Self(key: "requestID", value: value)
	}

	static func processedRequests(_ value: Int) -> Self {
		Self(key: "processedRequests", value: value)
	}

	static func queueDepth(_ value: Int) -> Self {
		Self(key: "queueDepth", value: value)
	}

	static func workers(_ value: Int) -> Self {
		Self(key: "workers", value: value)
	}

	static func latency(milliseconds: Int) -> Self {
		Self(key: "latencyMS", value: milliseconds)
	}

	static func errorBudget(_ value: Int) -> Self {
		Self(key: "errorBudget", value: value)
	}

	static func incidentMode(_ value: Bool) -> Self {
		Self(key: "incidentMode", value: value)
	}

	static func incomingRequests(_ value: Int) -> Self {
		Self(key: "incomingRequests", value: value)
	}

	static func completedRequests(_ value: Int) -> Self {
		Self(key: "completedRequests", value: value)
	}

	static func source(_ value: String) -> Self {
		Self(key: "source", value: value)
	}

	static func previousWorkers(_ value: Int) -> Self {
		Self(key: "previousWorkers", value: value)
	}

	static func burstSize(_ value: Int) -> Self {
		Self(key: "burstSize", value: value)
	}

	static func reason(_ value: String) -> Self {
		Self(key: "reason", value: value)
	}

	static func recordCount(_ value: Int) -> Self {
		Self(key: "recordCount", value: value)
	}
}
