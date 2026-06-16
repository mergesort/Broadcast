import Foundation

public extension Log {
	/// Supplies dates for buffered log entries.
	///
	/// Apps usually use ``Log/DateProvider/default``. Tests can inject a fixed
	/// provider so exported log strings are deterministic instead of depending on
	/// wall-clock time.
	struct DateProvider: Sendable {
		private let provideDate: @Sendable () -> Date

		public init(_ provideDate: @escaping @Sendable () -> Date) {
			self.provideDate = provideDate
		}

		/// The date to use for the next timestamped log entry.
		public var date: Date {
			self.provideDate()
		}
	}
}

public extension Log.DateProvider {
	/// A provider that returns the current wall-clock date.
	static let `default` = Self { .now }
}
