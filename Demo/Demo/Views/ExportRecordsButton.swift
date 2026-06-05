import Broadcast
import SwiftUI

struct ExportRecordsButton: View {
	let records: [Log.Record]

	var body: some View {
		Menu {
			ForEach(LogExport.Format.allCases) { format in
				ShareLink(item: format.text(for: self.records)) {
					Label("Share with \(format.title) log style", systemImage: format.systemImage)
				}
			}
		} label: {
			HStack(spacing: 8) {
				Image(systemName: "square.and.arrow.up")
					.font(.callout.weight(.semibold))

				Text("Share")
					.font(.callout.weight(.semibold))
			}
			.foregroundStyle(self.isDisabled ? Color.secondary : Color.blue)
			.padding(.horizontal, 14)
			.padding(.vertical, 9)
			.background((self.isDisabled ? Color.secondary : Color.blue).opacity(0.1))
			.overlay {
				Capsule()
					.stroke((self.isDisabled ? Color.secondary : Color.blue).opacity(0.18), lineWidth: 1)
			}
			.clipShape(Capsule())
		}
		.menuStyle(.button)
		.buttonStyle(.plain)
		.disabled(self.isDisabled)
	}

	private var isDisabled: Bool {
		self.records.isEmpty
	}
}
