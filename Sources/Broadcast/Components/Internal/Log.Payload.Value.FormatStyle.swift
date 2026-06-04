import Foundation

extension Log.Payload.Value {
	/// Formats this payload value with a Swift ``Foundation/FormatStyle``.
	func formatted<Style: Foundation.FormatStyle>(_ style: Style) -> Style.FormatOutput where Style.FormatInput == Self {
		style.format(self)
	}

	/// Broadcast's default formatter for typed payload values.
	///
	/// This centralizes nil handling, date formatting, duration formatting, and other
	/// primitive conversions so logging call-sites do not need ad-hoc stringification.
	struct FormatStyle: Foundation.FormatStyle {
		init() {}

		func format(_ value: Log.Payload.Value) -> String {
			switch value {
			case .string(let string): string ?? "nil"
			case .bool(let bool): bool ? "true" : "false"
			case .int(let int): String(describing: int)
			case .uuid(let uuid): uuid?.uuidString ?? "nil"
			case .url(let url): url?.absoluteString ?? "nil"
			case .date(let date): date?.formatted(.iso8601) ?? "nil"
			case .error(let error): String(describing: error)
			case .duration(let seconds): String(format: "%.2fs", seconds)
			}
		}
	}
}

extension FormatStyle where Self == Log.Payload.Value.FormatStyle {
	/// Broadcast's default payload value format.
	static var logPayloadValue: Self {
		Self()
	}
}
