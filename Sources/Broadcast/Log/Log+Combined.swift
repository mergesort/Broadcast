import Foundation

public extension Log {
	/// Returns a new logger that writes to this logger's destinations plus additional destinations.
	///
	/// Use this to compose destination sets without mutating the original logger. This
	/// is useful for adding console, buffered, remote, test, or feature-specific
	/// destinations while preserving the existing logger configuration.
	func combined(with destinations: [LoggingDestination]) -> Log {
		var allDestinations = self.destinations
		allDestinations.append(contentsOf: destinations)

		return Log(destinations: allDestinations)
	}

	/// Returns a new logger that writes to this logger's destinations plus one additional destination.
	func combined(with destination: LoggingDestination) -> Log {
		self.combined(with: [destination])
	}
}
