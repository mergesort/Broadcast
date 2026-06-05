import SwiftUI

struct DemoHeaderView: View {
	let traffic: TrafficState

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text("Server Simulator")
				.font(.largeTitle.bold())

			Text(self.traffic.modeLabel)
				.font(.headline)
				.monospaced()
				.foregroundStyle(self.traffic.isIncidentMode ? .red : .secondary)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
		.background(.background)
		.clipShape(RoundedRectangle(cornerRadius: 8))
	}
}

#Preview {
	DemoHeaderView(traffic: .initial)
		.padding()
}
