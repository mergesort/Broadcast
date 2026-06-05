import SwiftUI

@main
struct BroadcastDemoApp: App {
	@State private var demo = BroadcastDemoState()

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(self.demo)
		}
		#if os(macOS)
		.defaultSize(width: 1024, height: 768)
		#endif
	}
}
