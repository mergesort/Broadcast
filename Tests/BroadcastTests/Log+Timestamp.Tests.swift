import Broadcast
import Foundation
import Testing

struct TimestampTests {
	@Test
	func defaultsToCurrentTimestamp() {
		let before = Date()
		let timestamp = Log.Timestamp()
		let now = Log.Timestamp.now
		let after = Date()

		#expect(timestamp.date >= before)
		#expect(timestamp.date <= after)
		#expect(now.date >= before)
		#expect(now.date <= after)
	}

	@Test
	func formatsDefaultTimestamp() {
		let date = Date(timeIntervalSince1970: 0)

		#expect(Log.Timestamp(date).formatted(.default) == "1970-01-01T00:00:00Z")
	}

	@Test
	func supportsTimestampFormatStyle() {
		let dateProvider = Log.DateProvider { Date(timeIntervalSince1970: 42) }
		let timestampFormatStyle = Log.Timestamp.FormatStyle.timestamp

		#expect(timestampFormatStyle.format(Log.Timestamp(dateProvider.date)) == "42")
	}
}
