import SwiftUI

/// Broadcast Demo User Guide
///
/// Broadcast's demo app is a small operations dashboard for a simulated request
/// pipeline. The UI is intentionally simple: press the action buttons to create
/// operational events, switch between log feeds to inspect where each event was
/// routed, then use Copy or Share to export the same records in different
/// `Log.Record` formats.
///
/// Start here when exploring the demo:
///
/// 1. `BroadcastDemoApp` owns one `BroadcastDemoState` and injects it into SwiftUI.
///    This keeps app state, logging, and UI refreshes in one observable model.
/// 2. `Logging/Logger+Demo.swift` exposes the app's shared `log`, mirroring the
///    integration style used by real apps: a single composed logger near the
///    composition root, used from call sites as `log.info(...)`.
/// 3. `Logging/DemoLoggers.swift` is the logger graph. It wires Broadcast
///    destinations together:
///    - `ConsoleLogger` writes canonical log lines to OSLog.
///    - `SessionLogger` powers the live in-app feed.
///    - `SessionLogger(timestampFormatStyle: .timestamp)` powers the metrics feed.
///    - `AuditLogger` wraps `MultiSessionLogger` for persisted audit
///      history.
///    - The shared `log` fans out to the normal live operations pipeline and audit
///      storage, while `operationsLog`, `metricsLog`, and `auditLog` remain available
///      for intentionally specialized routes.
/// 4. `BroadcastDemoState` shows the call-site style. Shared events use
///    `log.info(...)` or `log.warn(...)`; destination-specific events use
///    `self.loggers.metricsLog` or `self.loggers.auditLog` to make routing explicit.
/// 5. `Logging/Log.Category+Demo.swift` and `Logging/Log.Payload+Demo.swift` show how
///    an app defines its own durable logging vocabulary instead of scattering raw
///    strings and ad-hoc payload keys through feature code.
/// 6. `Logging/LogExport.swift` and the Copy/Share buttons show the formatter story.
///    The same semantic `Log.Record` values can be exported as Broadcast's default
///    text format, Stripe-style canonical log lines, or structured JSON.
/// 7. `Sources/Broadcast/Components/FormatStyles/` contains the library-side
///    formatter implementations that make those export choices possible.
///
/// To understand the demo from the UI, run it and watch the feeds while triggering
/// actions:
///
/// - `Live` shows normal operational logs from the current run.
/// - `Metrics` shows metric-oriented samples routed to a metrics buffer.
/// - `Audit` shows persisted or audit-specific records and can be filtered by
///   category.
/// - `Copy` and `Share` menus demonstrate that destinations preserve semantic
///   records first, then format them at the edge for humans, tools, or agents.
///
/// The key concept is that Broadcast call sites create structured `Log.Record`
/// values once. Destinations decide where those records go, buffers keep the records
/// inspectable, and format styles decide how records become text only when they are
/// displayed, exported, or sent to OSLog.
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
