import Foundation

public extension Log {
	/// Returns a new log that writes to this log's destinations plus additional destinations.
	///
	/// Use this when one package, feature, or workflow needs its own destination
	/// without losing the app-wide logger. The returned ``Log`` keeps the same
	/// `log.info` API, but each record also goes to the extra destinations.
	func combined(with destinations: [LoggingDestination]) -> Log {
		var allDestinations = self.destinations
		allDestinations.append(contentsOf: destinations)

		return Log(destinations: allDestinations)
	}

	/// Returns a new log that writes to this log's destinations plus one additional destination.
	func combined(with destination: LoggingDestination) -> Log {
		self.combined(with: [destination])
	}
}
