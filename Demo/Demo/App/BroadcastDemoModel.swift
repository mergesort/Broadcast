import Broadcast
import Foundation
import Observation

@MainActor
@Observable
final class BroadcastDemoState {
	var traffic = TrafficState.initial
	var selectedFeed = LogFeed.live {
		didSet {
			self.refreshDisplayedLogs()
		}
	}
	var selectedAuditCategory = AuditCategoryFilter.all {
		didSet {
			self.refreshDisplayedLogs()
		}
	}
	var displayedRecords: [Log.Record] = []
	var exportText = ""

	@ObservationIgnored private let loggers = DemoLoggers()
	@ObservationIgnored private var simulation = TrafficSimulation()
	@ObservationIgnored private var simulationTask: Task<Void, Never>?

	init() {
		self.loggers.operationsLog.info(
			.diagnostic,
			"Dashboard initialized",
			category: .operations,
			payload: self.traffic.payload(additionalPayload: [.result("Ready")])
		)
		self.loggers.auditLog.info(
			.diagnostic,
			"Dashboard initialized",
			category: .operations,
			payload: self.traffic.payload(additionalPayload: [.result("Ready")])
		)
		self.refreshDisplayedLogs()
	}

	var auditCategoryBreakdown: [(AuditCategoryFilter, Int)] {
		AuditCategoryFilter.categoryCases.map { category in
			(category, self.loggers.auditLogger.records().filter { record in
				category.matches(record)
			}.count)
		}
	}

	var totalRecordCount: Int {
		self.loggers.liveLogger.records().count
			+ self.loggers.metricsLogger.records().count
			+ self.loggers.auditLogger.records().count
	}

	func start() {
		guard self.simulationTask == nil else {
			return
		}

		self.loggers.operationsLog.info(
			.event,
			"Realtime simulation started",
			category: .operations,
			payload: self.traffic.payload()
		)
		self.refreshDisplayedLogs()

		self.simulationTask = Task { @MainActor [weak self] in
			while !Task.isCancelled {
				try? await Task.sleep(for: .seconds(1.2))
				self?.advanceSimulation()
			}
		}

		Task { [weak self] in
			guard let self else {
				return
			}

			await self.loggers.auditLogger.prepareHistory()
			self.loggers.auditLog.info(
				.diagnostic,
				"Loaded persisted audit history",
				category: .storage,
				payload: [
					.recordCount(self.loggers.auditLogger.records().count),
					.result("Loaded")
				]
			)
			self.refreshDisplayedLogs()
		}
	}

	func processRequest() {
		let request = self.simulation.processRequest(source: "Manual", state: &self.traffic)
		self.log(request)
		self.refreshDisplayedLogs()
	}

	func runRequestBurst() {
		let burst = self.simulation.runBurst(state: &self.traffic)

		for request in burst.requests {
			self.log(request)
		}

		self.loggers.auditLog.info(
			.action,
			"Processed request burst",
			category: .traffic,
			payload: self.traffic.payload(additionalPayload: [
				.burstSize(burst.size),
				.result("Completed")
			])
		)
		self.refreshDisplayedLogs()
	}

	func scaleWorkers() {
		let change = self.simulation.scaleWorkers(state: &self.traffic)

		self.loggers.operationsLog.info(
			.state,
			"Scaled workers",
			category: .workers,
			payload: self.traffic.payload(additionalPayload: [
				.previousWorkers(change.previousWorkers),
				.result("Applied")
			])
		)
		self.loggers.auditLog.info(
			.state,
			"Worker pool changed",
			category: .workers,
			payload: self.traffic.payload(additionalPayload: [
				.previousWorkers(change.previousWorkers),
				.result("Applied")
			])
		)
		self.refreshDisplayedLogs()
	}

	func toggleIncidentMode() {
		let change = self.simulation.toggleIncidentMode(state: &self.traffic)

		switch change.status {
		case .triggered:
			self.loggers.operationsLog.warn(
				.event,
				"Incident triggered",
				category: .incidents,
				payload: self.traffic.payload(additionalPayload: [.result("Investigating")])
			)
			self.loggers.auditLog.warn(
				.event,
				"Incident triggered",
				category: .incidents,
				payload: self.traffic.payload(additionalPayload: [.result("Investigating")])
			)
		case .resolved:
			self.loggers.operationsLog.info(
				.state,
				"Incident resolved",
				category: .incidents,
				payload: self.traffic.payload(additionalPayload: [.result("Recovered")])
			)
			self.loggers.auditLog.info(
				.state,
				"Incident resolved",
				category: .incidents,
				payload: self.traffic.payload(additionalPayload: [.result("Recovered")])
			)
		}

		self.refreshDisplayedLogs()
	}

	func simulateFailure() {
		let failure = self.simulation.simulateFailure(state: &self.traffic)

		self.loggers.operationsLog.error(
			.diagnostic,
			"Request failed",
			category: .pipeline,
			payload: self.traffic.payload(additionalPayload: [
				.requestID(failure.requestID),
				.reason("Retry limit reached"),
				.result("Failed")
			])
		)
		self.loggers.auditLog.error(
			.event,
			"Failure captured in audit buffer",
			category: .incidents,
			payload: [
				.requestID(failure.requestID),
				.errorBudget(self.traffic.errorBudget)
			]
		)
		self.refreshDisplayedLogs()
	}

	func clearAllRecords() {
		Task { @MainActor in
			await self.loggers.removeAll()
			self.refreshDisplayedLogs()
		}
	}

	private func advanceSimulation() {
		let tick = self.simulation.advance(state: &self.traffic)

		if tick.shouldLogMetricsSample {
			self.loggers.metricsLog.debug(
				.metric,
				"Traffic sample",
				category: .traffic,
				payload: self.traffic.payload(additionalPayload: tick.payload)
			)
		}

		if tick.shouldLogAuditSample {
			self.loggers.auditLog.debug(
				.metric,
				"Traffic sample audited",
				category: .traffic,
				payload: self.traffic.payload(additionalPayload: tick.payload)
			)
		}

		if tick.queuePressureDidStart {
			self.loggers.operationsLog.warn(
				.state,
				"Queue pressure increased",
				category: .pipeline,
				payload: self.traffic.payload(additionalPayload: [.result("Backpressure")])
			)
		}

		self.refreshDisplayedLogs()
	}

	private func log(_ request: ProcessedRequest) {
		let payload = self.traffic.payload(additionalPayload: request.payload)

		self.loggers.operationsLog.info(
			.action,
			"Processed request",
			category: .pipeline,
			payload: payload
		)
		self.loggers.metricsLog.debug(
			.metric,
			"Latency sampled",
			category: .metrics,
			payload: [
				.requestID(request.requestID),
				.latency(milliseconds: request.latency)
			]
		)
		self.loggers.auditLog.info(
			.action,
			"Request processed",
			category: .pipeline,
			payload: payload
		)
	}

	private func refreshDisplayedLogs() {
		let records = self.loggers.bufferedLogger(for: self.selectedFeed)
			.records()

		self.displayedRecords = records
			.filter { record in
				guard self.selectedFeed == .audit else {
					return true
				}

				return self.selectedAuditCategory.matches(record)
			}
			.sorted(by: { $0.timestamp.date > $1.timestamp.date })

		self.exportText = LogExport.text(
			for: self.displayedRecords,
			formatter: self.loggers.bufferedLogger(for: self.selectedFeed).recordFormatter
		)
	}
}
