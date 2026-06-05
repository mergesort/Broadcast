import SwiftUI

struct FlowLayout: Layout {
	var spacing: CGFloat

	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		self.layout(in: proposal.width ?? 320, subviews: subviews).size
	}

	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		for item in self.layout(in: bounds.width, subviews: subviews).items {
			subviews[item.index].place(
				at: CGPoint(x: bounds.minX + item.frame.minX, y: bounds.minY + item.frame.minY),
				proposal: ProposedViewSize(item.frame.size)
			)
		}
	}

	private func layout(in width: CGFloat, subviews: Subviews) -> (items: [(index: Int, frame: CGRect)], size: CGSize) {
		var x: CGFloat = 0
		var y: CGFloat = 0
		var rowHeight: CGFloat = 0
		var items: [(Int, CGRect)] = []
		let maxWidth = max(width, 1)

		for index in subviews.indices {
			let size = subviews[index].sizeThatFits(.unspecified)

			if x > 0, x + size.width > maxWidth {
				x = 0
				y += rowHeight + self.spacing
				rowHeight = 0
			}

			items.append((index, CGRect(origin: CGPoint(x: x, y: y), size: size)))
			x += size.width + self.spacing
			rowHeight = max(rowHeight, size.height)
		}

		return (items, CGSize(width: maxWidth, height: y + rowHeight))
	}
}
