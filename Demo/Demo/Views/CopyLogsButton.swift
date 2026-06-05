import Broadcast
import SwiftUI

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct CopyLogsButton: View {
	let records: [Log.Record]

	private var isDisabled: Bool {
		self.records.isEmpty
	}

	var body: some View {
		Menu {
			ForEach(LogExport.Format.allCases) { format in
				Button(action: {
					self.copyLogs(format: format)
				}, label: {
					Label("Copy as \(format.title)", systemImage: format.systemImage)
				})
			}
		} label: {
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
		.menuStyle(.button)
		.buttonStyle(.plain)
		.disabled(self.isDisabled)
	}

	private func copyLogs(format: LogExport.Format) {
		let text = format.text(for: self.records)

		#if os(macOS)
		NSPasteboard.general.clearContents()
		NSPasteboard.general.setString(text, forType: .string)
		#elseif canImport(UIKit)
		UIPasteboard.general.string = text
		#endif
	}
}
