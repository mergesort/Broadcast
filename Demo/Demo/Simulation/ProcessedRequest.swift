import Broadcast
import Foundation

struct ProcessedRequest {
	let requestID: UUID
	let latency: Int
	let source: String

	var payload: [Log.Payload] {
		[
			.requestID(self.requestID),
			.latency(milliseconds: self.latency),
			.source(self.source),
			.result("Success")
		]
	}
}
