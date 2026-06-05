import SwiftUI

struct MetricsGridView: View {
	let traffic: TrafficState

	var body: some View {
		LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
			MetricTile(title: "Processed", value: "\(self.traffic.processedRequests)", tint: .green)
			MetricTile(title: "Queue", value: "\(self.traffic.queueDepth)", tint: .blue)
			MetricTile(title: "Workers", value: "\(self.traffic.activeWorkers)", tint: .indigo)
			MetricTile(title: "Latency", value: "\(self.traffic.averageLatencyMS) ms", tint: .orange)
			#if os(macOS)
			MetricTile(title: "Error Rate", value: "\(self.traffic.errorRatePercent)%", tint: .red)
			#endif
		}
	}
}

private struct MetricTile: View {
	let title: String
	let value: String
	let tint: Color

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text(self.title)
				.font(.caption.weight(.semibold))
				.foregroundStyle(.secondary)

			Text(self.value)
				.font(.title2.monospacedDigit().bold())
				.foregroundStyle(self.tint)
				.lineLimit(1)
				.minimumScaleFactor(0.7)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
		.background(.background)
		.clipShape(RoundedRectangle(cornerRadius: 8))
	}
}

#Preview {
	MetricsGridView(traffic: .initial)
		.padding()
}
