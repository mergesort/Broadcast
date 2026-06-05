import Foundation

public extension Log.Payload {
	/// Formats this payload with a Swift ``Foundation/FormatStyle``.
	///
	/// Custom ``Log.Record`` formatters can use this to render payload values without
	/// depending on Broadcast's internal typed payload value representation. Most app
	/// logging call-sites should not need to call this directly.
	func formatted<Style: Foundation.FormatStyle>(_ style: Style) -> Style.FormatOutput where Style.FormatInput == Self {
		style.format(self)
	}

	/// Broadcast's default `key=value` payload formatter.
	///
	/// This exists primarily for custom ``Log.Record`` formatters. Prefer typed
	/// ``Log.Payload`` initializers at call-sites rather than pre-formatting payload
	/// values manually. Broadcast keeps the underlying payload value enum internal so
	/// custom record formatters can render payloads without depending on that storage.
	struct FormatStyle: Foundation.FormatStyle, Sendable {
		public init() {}

		public func format(_ value: Log.Payload) -> String {
			Log.Record.KeyValuePair(
				key: value.key,
				value: value.value.formatted(.logPayloadValue)
			)
			.formatted(.raw)
		}
	}
}

// MARK: FormatStyle

public extension FormatStyle where Self == Log.Payload.FormatStyle {
	/// Broadcast's default payload format.
	static var logPayload: Self {
		Self()
	}
}
