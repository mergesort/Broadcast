import Broadcast
import SwiftUI

struct LogRecordRow: View {
	let record: Log.Record

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			HStack(alignment: .firstTextBaseline, spacing: 8) {
				Text(self.record.level.rawValue.uppercased())
					.font(.footnote.bold())
					.foregroundStyle(self.levelColor)
					.frame(width: 64, alignment: .leading)

				Text(self.record.message)
					.font(.headline.weight(.semibold))
					.lineLimit(2)

				Spacer()
			}

			HStack(spacing: 8) {
				if let signal = self.record.signal {
					Text(signal.identifier)
				}

				if let category = self.record.category {
					Text(category.identifier)
				}

				Text(self.record.timestamp.date.formatted(date: .omitted, time: .standard))
			}
			.font(.callout)
			.foregroundStyle(.secondary)

			if !self.record.payload.isEmpty {
				Text(self.record.payload.map({ $0.formatted(.logPayload) }).joined(separator: ", "))
					.font(.callout.monospaced())
					.foregroundStyle(.secondary)
					.textSelection(.enabled)
			}
		}
		.padding(12)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(Color.secondaryAppBackground)
		.clipShape(RoundedRectangle(cornerRadius: 8))
	}

	private var levelColor: Color {
		switch self.record.level {
		case .debug: .secondary
		case .info: .green
		case .warn: .orange
		case .error: .red
		case .fault: .purple
		}
	}
}
