import SwiftUI

struct ActionPanelView: View {
	let isIncidentMode: Bool
	let processRequest: () -> Void
	let runRequestBurst: () -> Void
	let scaleWorkers: () -> Void
	let toggleIncidentMode: () -> Void
	let simulateFailure: () -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("Simulation Actions")
				.font(.title2.bold())

			LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
				ActionButton(
					title: "Process Request",
					detail: "One request",
					systemImage: "checkmark",
					tint: .green,
					action: self.processRequest
				)

				ActionButton(
					title: "Process Request Burst",
					detail: "3-6 requests",
					systemImage: "bolt.fill",
					tint: .blue,
					action: self.runRequestBurst
				)

				ActionButton(
					title: "Scale Servers",
					detail: "Add workers",
					systemImage: "arrow.up.right",
					tint: .indigo,
					action: self.scaleWorkers
				)

				ActionButton(
					title: self.isIncidentMode ? "Resolve Incident" : "Spawn Incident",
					detail: self.isIncidentMode ? "Recover traffic" : "Warn the team",
					systemImage: self.isIncidentMode ? "checkmark" : "exclamationmark",
					tint: self.isIncidentMode ? .green : .orange,
					action: self.toggleIncidentMode
				)

				ActionButton(
					title: "Failure",
					detail: "Log an error",
					systemImage: "xmark",
					tint: .red,
					action: self.simulateFailure
				)
			}
		}
		.padding()
		.background(.background)
		.clipShape(RoundedRectangle(cornerRadius: 8))
	}
}

private struct ActionButton: View {
	let title: String
	let detail: String
	let systemImage: String
	let tint: Color
	let action: () -> Void

	var body: some View {
		Button(action: self.action) {
			HStack(spacing: 10) {
				Image(systemName: self.systemImage)
					.font(.body.weight(.bold))
					.foregroundStyle(self.tint)
					.frame(width: 36, height: 36)
					.background(self.tint.opacity(0.14))
					.clipShape(Circle())

				VStack(alignment: .leading, spacing: 2) {
					Text(self.title)
						.font(.headline.weight(.semibold))
						.foregroundStyle(.primary)
						.lineLimit(1)
						.minimumScaleFactor(0.75)

					Text(self.detail)
						.font(.caption.weight(.semibold))
						.foregroundStyle(.secondary)
						.lineLimit(1)
						.minimumScaleFactor(0.75)
				}

				Spacer(minLength: 0)
			}
			.padding(.horizontal, 14)
			.padding(.vertical, 10)
			.frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
			.background(self.tint.opacity(0.08))
			.overlay {
				RoundedRectangle(cornerRadius: 8)
					.stroke(self.tint.opacity(0.22), lineWidth: 1)
			}
			.clipShape(RoundedRectangle(cornerRadius: 8))
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	ActionPanelView(
		isIncidentMode: false,
		processRequest: {},
		runRequestBurst: {},
		scaleWorkers: {},
		toggleIncidentMode: {},
		simulateFailure: {}
	)
	.padding()
}
