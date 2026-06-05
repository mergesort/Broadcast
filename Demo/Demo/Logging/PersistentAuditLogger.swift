import Boutique
import Broadcast
import Foundation

@MainActor
final class PersistentAuditLogger: BufferedLoggingDestination {
	let dateProvider: Log.DateProvider

	private let limit: Int
	private let store: Store<Log.Record>
	private let logger: MultiSessionLogger

	init(limit: Int = 5_000) {
		let store = Store<Log.Record>(
			storage: SQLiteStorageEngine.default(appendingPath: "BroadcastDemoAuditLogs")
		)

		self.limit = limit
		self.store = store
		self.logger = MultiSessionLogger(store: store)
		self.dateProvider = self.logger.dateProvider
	}

	var recordFormatter: Log.Record.Formatter {
		self.logger.recordFormatter
	}

	func log(_ record: Log.Record) {
		self.logger.log(record)
	}

	func records() -> [Log.Record] {
		self.cappedRecords(from: self.logger.records())
	}

	func prepareHistory() async {
		try? await self.store.itemsHaveLoaded()
		try? await Task.sleep(for: .milliseconds(150))
	}

	func removeAll() async {
		await self.logger.removeAll()
	}

	private func cappedRecords(from records: [Log.Record]) -> [Log.Record] {
		Array(
			records
				.sorted(by: { $0.timestamp.date < $1.timestamp.date })
				.suffix(self.limit)
		)
	}
}
