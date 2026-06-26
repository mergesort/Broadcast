#if MultiSessionLogging
import Boutique
import Foundation
import Synchronization

/// A persistent destination for logs that should survive app relaunches.
///
/// Use ``MultiSessionLogger`` when the useful evidence may have happened before
/// the current launch. The host app owns the Boutique `Store` configuration, so it
/// can choose the right storage location, app group, and retention policy.
public final class MultiSessionLogger: BufferedLoggingDestination {
	public let dateProvider: Log.DateProvider
	private let recordStorage: Mutex<[Log.Record]>
	private let storage: MultiSessionLogStorage
	private let pendingStorageWrite = Mutex<Task<Void, Never>?>(nil)
	private let timestampFormatStyle: Log.Timestamp.FormatStyle

	/// Creates a multi-session logger backed by a Boutique store.
	///
	/// The logger keeps an in-memory snapshot for synchronous reads and serializes
	/// writes into the store. Inject a fixed ``Log/DateProvider`` in tests when
	/// deterministic output matters.
	@MainActor
	public init(store: Store<Log.Record>, dateProvider: Log.DateProvider = .default, timestampFormatStyle: Log.Timestamp.FormatStyle = .default) {
		self.recordStorage = Mutex(store.items)
		self.storage = MultiSessionLogStorage(store: store)
		self.dateProvider = dateProvider
		self.timestampFormatStyle = timestampFormatStyle

		self.setPendingStorageWrite(
			Task { [weak self, storage] in
				let records = await storage.loadedRecords()
				self?.mergePersistedRecords(records)
			}
		)
	}

	public var recordFormatter: Log.Record.Formatter {
		Log.Record.Formatter(timestampFormatStyle: self.timestampFormatStyle)
	}

	public func log(_ record: Log.Record) {
		self.append(record)
	}

	/// Returns all buffered records currently known to the logger.
	public func records() -> [Log.Record] {
		self.recordStorage.withLock {
			$0
		}
	}
}

extension MultiSessionLogger {
	func flush() async {
		await self.currentPendingStorageWrite()?.value
	}

	public func removeAll() async {
		await self.currentPendingStorageWrite()?.value

		self.recordStorage.withLock {
			$0.removeAll()
		}

		self.enqueueStorageWrite { [storage] in
			await storage.removeAll()
		}

		await self.currentPendingStorageWrite()?.value
	}
}

// MARK: Private

private extension MultiSessionLogger {
	func append(_ record: Log.Record) {
		self.recordStorage.withLock {
			$0.append(record)
		}

		self.enqueueStorageWrite { [storage] in
			await storage.append(record)
		}
	}

	func mergePersistedRecords(_ persistedRecords: [Log.Record]) {
		self.recordStorage.withLock {
			let existingIDs = Set($0.map(\.id))
			let recordsMissingFromSnapshot = persistedRecords.filter({ !existingIDs.contains($0.id) })
			$0.insert(contentsOf: recordsMissingFromSnapshot, at: 0)
		}
	}

	func currentPendingStorageWrite() -> Task<Void, Never>? {
		self.pendingStorageWrite.withLock {
			$0
		}
	}

	func setPendingStorageWrite(_ task: Task<Void, Never>) {
		self.pendingStorageWrite.withLock {
			$0 = task
		}
	}

	func enqueueStorageWrite(_ operation: @escaping @Sendable () async -> Void) {
		self.pendingStorageWrite.withLock {
			let previousTask = $0
			$0 = Task {
				await previousTask?.value
				await operation()
			}
		}
	}
}

// MARK: MultiSessionLogStorage

@MainActor
private final class MultiSessionLogStorage {
	@Stored private var records: [Log.Record]

	init(store: Store<Log.Record>) {
		self._records = Stored(in: store)
	}

	func loadedRecords() async -> [Log.Record] {
		try? await self.$records.itemsHaveLoaded()
		return self.records
	}

	func append(_ record: Log.Record) async {
		try? await self.$records.insert(record)
	}

	func removeAll() async {
		try? await self.$records.removeAll()
	}
}

#endif
