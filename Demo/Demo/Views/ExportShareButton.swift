import SwiftUI

struct ExportShareButton: View {
	let title: String
	let text: String

	private var isDisabled: Bool {
		self.text.isEmpty
	}

	var body: some View {
		ShareLink(item: self.text) {
			HStack(spacing: 8) {
				Image(systemName: "square.and.arrow.up")
					.font(.callout.weight(.semibold))

				Text(self.title)
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
		.buttonStyle(.plain)
		.disabled(self.isDisabled)
	}
}
