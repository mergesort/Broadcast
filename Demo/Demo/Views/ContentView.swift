import SwiftUI

struct ContentView: View {
	@Environment(BroadcastDemoState.self) private var demo

	var body: some View {
		@Bindable var demo = self.demo

		ScrollView {
			VStack(alignment: .leading, spacing: 18) {
				DemoHeaderView(traffic: demo.traffic)

				MetricsGridView(traffic: demo.traffic)

				ActionPanelView(
					isIncidentMode: demo.traffic.isIncidentMode,
					processRequest: demo.processRequest,
					runRequestBurst: demo.runRequestBurst,
					scaleWorkers: demo.scaleWorkers,
					toggleIncidentMode: demo.toggleIncidentMode,
					simulateFailure: demo.simulateFailure
				)

				LogFeedView(
					selectedFeed: $demo.selectedFeed,
					selectedAuditCategory: $demo.selectedAuditCategory,
					records: demo.displayedRecords,
					totalRecordCount: demo.totalRecordCount,
					auditCategoryBreakdown: demo.auditCategoryBreakdown,
					exportText: demo.exportText,
					clearAllRecords: demo.clearAllRecords
				)
			}
			.padding()
			.frame(maxWidth: 1180, alignment: .topLeading)
		}
		.background(Color.appBackground)
		.task {
			demo.start()
		}
	}
}

#Preview {
	ContentView()
		.environment(BroadcastDemoState())
}
