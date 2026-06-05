import Foundation

extension Log.Record {
	struct KeyValuePair: Sendable {
		let key: String
		let value: String

		func formatted<Style: Foundation.FormatStyle>(_ style: Style) -> Style.FormatOutput where Style.FormatInput == Self {
			style.format(self)
		}
	}
}
