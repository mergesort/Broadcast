import SwiftUI

struct AuditCategoryBar: View {
	@Binding var selection: AuditCategoryFilter
	let breakdown: [(AuditCategoryFilter, Int)]

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			FlowLayout(spacing: 8) {
				ForEach(AuditCategoryFilter.allCases) { category in
					Button {
						self.selection = category
					} label: {
						Text(category.title)
							.font(.caption.weight(.semibold))
					}
					.buttonStyle(.bordered)
					.tint(self.selection == category ? .blue : .secondary)
				}
			}

			FlowLayout(spacing: 8) {
				ForEach(self.breakdown, id: \.0) { category, count in
					HStack(spacing: 4) {
						Text(category.title)
						Text("\(count)")
							.foregroundStyle(.secondary)
					}
					.font(.caption.monospacedDigit())
					.padding(.horizontal, 8)
					.padding(.vertical, 5)
					.background(Color.secondaryAppBackground)
					.clipShape(Capsule())
				}
			}
		}
	}
}
