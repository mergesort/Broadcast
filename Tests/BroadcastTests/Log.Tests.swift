import Broadcast
import Testing

struct LogTests {
	@Test
	func writesPlainLogsToEveryDestination() {
		let firstDestination = CapturingLoggingDestination()
		let secondDestination = CapturingLoggingDestination()
		let log = Log(destinations: [firstDestination, secondDestination])

		log.info("Created", "Reminder", 3)

		#expect(firstDestination.records.map(\.message) == ["Created, Reminder, 3"])
		#expect(secondDestination.records.map(\.message) == ["Created, Reminder, 3"])
		#expect(firstDestination.records.map(\.level) == [.info])
		#expect(secondDestination.records.map(\.level) == [.info])
	}

	@Test
	func writesVariadicValuesThroughLoggingDestinationExtension() {
		let destination = CapturingLoggingDestination()
		let loggingDestination: any LoggingDestination = destination

		loggingDestination.info("Created", "Reminder", 3)

		#expect(destination.records.map(\.message) == ["Created, Reminder, 3"])
		#expect(destination.records.map(\.level) == [.info])
	}

	@Test
	func formatsArgumentValuesThroughLoggingDestinationHelper() {
		let values: [Any] = ["Created", 3, true, ["Groceries", "Errands"]]

		#expect(
			CapturingLoggingDestination.formattedArgumentValues(values) == [
				"Created",
				"3",
				"true",
				"[\"Groceries\", \"Errands\"]"
			]
		)
	}

	@Test
	func combinesDestinations() {
		let initialDestination = CapturingLoggingDestination()
		let additionalDestination = CapturingLoggingDestination()
		let log = Log(destinations: [initialDestination])
			.combined(with: additionalDestination)

		log.warn("Reminder queue full")

		#expect(initialDestination.records.map(\.message) == ["Reminder queue full"])
		#expect(additionalDestination.records.map(\.message) == ["Reminder queue full"])
		#expect(initialDestination.records.map(\.level) == [.warn])
		#expect(additionalDestination.records.map(\.level) == [.warn])
	}

	@Test
	func writesBlankLinesToEveryDestination() {
		let firstDestination = CapturingLoggingDestination()
		let secondDestination = CapturingLoggingDestination()
		let log = Log(destinations: [firstDestination, secondDestination])

		log.info()

		#expect(firstDestination.records.map(\.message) == [""])
		#expect(secondDestination.records.map(\.message) == [""])
		#expect(firstDestination.infoLogs == [""])
		#expect(secondDestination.infoLogs == [""])
	}
}
