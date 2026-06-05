import Broadcast
import Foundation

// MARK: TrafficBurst

struct TrafficBurst {
	let size: Int
	let requests: [ProcessedRequest]
}

// MARK: TrafficTick

struct TrafficTick {
	let incomingRequests: Int
	let completedRequests: Int
	let shouldLogMetricsSample: Bool
	let shouldLogAuditSample: Bool
	let queuePressureDidStart: Bool

	var payload: [Log.Payload] {
		[
			.incomingRequests(self.incomingRequests),
			.completedRequests(self.completedRequests)
		]
	}
}

// MARK: WorkerScale

struct WorkerScale {
	let previousWorkers: Int
}

// MARK: IncidentChange

struct IncidentChange {
	enum Status {
		case triggered
		case resolved
	}

	let status: Status
}

// MARK: RequestFailure

struct RequestFailure {
	let requestID: UUID
}
