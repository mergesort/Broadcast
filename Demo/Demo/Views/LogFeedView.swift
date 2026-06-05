import Broadcast
import SwiftUI

struct LogFeedView: View {
	@Binding var selectedFeed: LogFeed
	@Binding var selectedAuditCategory: AuditCategoryFilter
	let records: [Log.Record]
	let totalRecordCount: Int
	let auditCategoryBreakdown: [(AuditCategoryFilter, Int)]
	let exportText: String
	let clearAllRecords: () -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			self.feedPicker
			LogToolsView(
				selectedFeed: self.selectedFeed,
				recordCount: self.records.count,
				totalRecordCount: self.totalRecordCount,
				exportText: self.exportText,
				clearAllRecords: self.clearAllRecords
			)

			if self.selectedFeed == .audit {
				AuditCategoryBar(
					selection: self.$selectedAuditCategory,
					breakdown: self.auditCategoryBreakdown
				)
			}

			LazyVStack(spacing: 8) {
				ForEach(self.records) { record in
					LogRecordRow(record: record)
				}
			}
		}
		.padding()
		.background(.background)
		.clipShape(RoundedRectangle(cornerRadius: 8))
	}

	@ViewBuilder
	private var feedPicker: some View {
		#if os(macOS)
		HStack(alignment: .center, spacing: 12) {
			Text("Feed")
				.font(.headline)
				.frame(minWidth: 56, alignment: .leading)

			self.picker
				.frame(maxWidth: 360, alignment: .leading)

			Spacer()
		}
		#else
		self.picker
			.frame(maxWidth: .infinity)
		#endif
	}

	private var picker: some View {
		Picker("Feed", selection: self.$selectedFeed) {
			ForEach(LogFeed.allCases) { feed in
				Text(feed.title).tag(feed)
			}
		}
		.labelsHidden()
		.pickerStyle(.segmented)
	}
}

private struct LogToolsView: View {
	let selectedFeed: LogFeed
	let recordCount: Int
	let totalRecordCount: Int
	let exportText: String
	let clearAllRecords: () -> Void

	var body: some View {
		#if os(macOS)
		HStack(alignment: .center, spacing: 10) {
			self.recordCountLabel

			Spacer()

			self.actions
		}
		#else
		VStack(alignment: .leading, spacing: 10) {
			self.recordCountLabel

			FlowLayout(spacing: 8) {
				self.actions
			}
		}
		#endif
	}

	private var recordCountLabel: some View {
		Text("\(self.recordCount.formatted()) records")
			.font(.callout.weight(.semibold))
			.foregroundStyle(.secondary)
	}

	@ViewBuilder
	private var actions: some View {
		CopyLogsButton(text: self.exportText)
		ExportShareButton(title: "Share", text: self.exportText)

		Menu {
			Button(role: .destructive, action: self.clearAllRecords) {
				Label("Clear All Records", systemImage: "trash")
			}
		} label: {
			Label("Clear All", systemImage: "trash")
				.font(.callout.weight(.semibold))
				.padding(.horizontal, 14)
				.padding(.vertical, 9)
				.background(Color.red.opacity(0.08))
				.overlay {
					Capsule()
						.stroke(Color.red.opacity(0.18), lineWidth: 1)
				}
				.clipShape(Capsule())
		}
		.menuStyle(.button)
		.buttonStyle(.plain)
		.disabled(self.totalRecordCount == 0)
	}
}
