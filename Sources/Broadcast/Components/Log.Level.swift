import Foundation

public extension Log {
	/// Severity levels used by Broadcast destinations.
	///
	/// Most integrations should call ``Log`` methods like `debug(_:)` and `info(_:)`
	/// rather than handling levels directly. Destination implementations use this
	/// type when rendering or storing level-specific output.
	enum Level: String, Codable, Sendable {
		case debug
		case info
		case warn
		case error
		case fault
	}
}
