import SwiftUI

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct CopyLogsButton: View {
	let text: String

	private var isDisabled: Bool {
		self.text.isEmpty
	}

	var body: some View {
		Button(action: self.copyLogs) {
			Label("Copy", systemImage: "doc.on.doc")
				.font(.callout.weight(.semibold))
				.foregroundStyle(self.isDisabled ? Color.secondary : Color.primary)
				.padding(.horizontal, 14)
				.padding(.vertical, 9)
				.background(Color.secondary.opacity(0.1))
				.overlay {
					Capsule()
						.stroke(Color.secondary.opacity(0.16), lineWidth: 1)
				}
				.clipShape(Capsule())
		}
		.buttonStyle(.plain)
		.disabled(self.isDisabled)
	}

	private func copyLogs() {
		#if os(macOS)
		NSPasteboard.general.clearContents()
		NSPasteboard.general.setString(self.text, forType: .string)
		#elseif canImport(UIKit)
		UIPasteboard.general.string = self.text
		#endif
	}
}
