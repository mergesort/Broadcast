import Foundation

struct TrafficSimulation {
	private var step = 0
	private var didLogQueuePressure = false

	mutating func advance(state: inout TrafficState) -> TrafficTick {
		self.step += 1
		let incomingRequests = Int.random(in: state.isIncidentMode ? 4...11 : 1...6)
		let completedRequests = min(
			state.queueDepth + incomingRequests,
			Int.random(in: state.activeWorkers...(state.activeWorkers * 3))
		)

		state.queueDepth = max(0, state.queueDepth + incomingRequests - completedRequests)
		state.processedRequests += completedRequests
		state.averageLatencyMS = max(
			40,
			min(600, state.averageLatencyMS + Int.random(in: state.isIncidentMode ? -8...45 : -18...16))
		)

		if state.isIncidentMode {
			state.errorBudget = max(0, state.errorBudget - Int.random(in: 0...2))
		}

		let queuePressureDidStart = state.queueDepth > 18 && !self.didLogQueuePressure

		if queuePressureDidStart {
			self.didLogQueuePressure = true
		} else if state.queueDepth < 10 {
			self.didLogQueuePressure = false
		}

		return TrafficTick(
			incomingRequests: incomingRequests,
			completedRequests: completedRequests,
			shouldLogMetricsSample: self.step.isMultiple(of: 3),
			shouldLogAuditSample: self.step.isMultiple(of: 5),
			queuePressureDidStart: queuePressureDidStart
		)
	}

	mutating func processRequest(source: String, state: inout TrafficState) -> ProcessedRequest {
		let requestID = UUID()
		let latency = max(35, state.averageLatencyMS + Int.random(in: -35...60))

		state.processedRequests += 1
		state.queueDepth = max(0, state.queueDepth - 1)
		state.averageLatencyMS = (state.averageLatencyMS + latency) / 2

		return ProcessedRequest(requestID: requestID, latency: latency, source: source)
	}

	mutating func runBurst(state: inout TrafficState) -> TrafficBurst {
		let size = Int.random(in: 3...6)
		let requests = (0..<size).map { _ in
			self.processRequest(source: "Burst", state: &state)
		}

		return TrafficBurst(size: size, requests: requests)
	}

	mutating func scaleWorkers(state: inout TrafficState) -> WorkerScale {
		let previousWorkers = state.activeWorkers

		state.activeWorkers = min(8, state.activeWorkers + Int.random(in: 1...2))
		state.queueDepth = max(0, state.queueDepth - Int.random(in: 1...4))

		return WorkerScale(previousWorkers: previousWorkers)
	}

	mutating func toggleIncidentMode(state: inout TrafficState) -> IncidentChange {
		state.isIncidentMode.toggle()

		if state.isIncidentMode {
			state.errorBudget = max(0, state.errorBudget - 9)
			state.queueDepth += Int.random(in: 4...9)
			return IncidentChange(status: .triggered)
		} else {
			state.errorBudget = min(100, state.errorBudget + 12)
			return IncidentChange(status: .resolved)
		}
	}

	mutating func simulateFailure(state: inout TrafficState) -> RequestFailure {
		state.errorBudget = max(0, state.errorBudget - 4)
		state.queueDepth += 2

		return RequestFailure(requestID: UUID())
	}
}
