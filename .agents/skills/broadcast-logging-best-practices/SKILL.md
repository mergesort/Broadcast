---
name: broadcast-logging-best-practices
description: Integrate Broadcast into a Swift app or package, including configuring shared Log destinations, dependency injection, structured Log.Signal, Log.Category, and Log.Payload APIs, app-specific logging helpers, buffered log export, and logging tests.
---

# Broadcast Logging Best Practices

Use this skill when integrating Broadcast into a Swift project. Treat Broadcast as an external reusable logging library; do not assume you are modifying Broadcast itself unless the user explicitly asks to work on the library.

## Integration Workflow

1. Add Broadcast as a dependency using the host project's normal package workflow.
2. Import `Broadcast` where logging is configured or called.
3. Create a shared `Log` instance from one or more destinations.
4. For app or app-specific package code, prefer one immutable app or package-scoped global `let log` so SwiftUI and non-SwiftUI surfaces share the same destination graph.
5. Add app-specific `Log.Category` values and `Log.Payload` helper factories in the integrating app or app-specific logging package, not in Broadcast.
6. Replace important free-form logs with structured logs where they help explain user-visible behavior, support diagnostics, startup, sync, entitlement, routing, persistence, or network decisions.
7. Validate with the host project's normal build and test commands.

## Core APIs

- `Log` fans out one log call to one or more destinations.
- `LoggingDestination` is the write-only sink protocol whose primitive is `log(_ record:)`; Broadcast provides default `debug`, `info`, `warn`, `error`, and `fault` convenience methods that create records.
- `BufferedLoggingDestination` extends `LoggingDestination` with `records()` for destinations that need access to canonical records, plus overridable default `logs()` text export.
- `ConsoleLogger` writes process-local output.
- `SessionLogger` buffers logs in memory for the current process.
- `MultiSessionLogger` buffers canonical `Log.Record` values across launches using persistent storage; use it only when the host app has configured the required persistence.
- `Log.Signal` describes the intent of a structured log. Defaults include `.action`, `.state`, `.event`, `.metric`, and `.diagnostic`.
- `Log.Category` describes a human-readable subsystem or area.
- `Log.Payload` stores typed key-value diagnostics and exposes public typed initializers so call-sites do not need to format values manually.
- `Log.Record` is the identifiable timestamped semantic structured log value that destinations format through `recordFormatter`, which defaults to Broadcast's standard single-line format; records create a UUID and current timestamp by default.
- `Log.Record.Formatter` is the type-erased destination-level formatter for structured `Log.Record` values.
- Built-in `Log.Record` format styles include `.default`, `.json`, `.tokenOptimized`, and `.canonicalLogLine`.
- `Log.DateProvider` supplies dates for buffered loggers, and `Log.Timestamp.FormatStyle` formats those dates; `Log.Timestamp` defaults to the current date and is available as `Log.Timestamp.now`, but fixed date providers are still the deterministic-test path for logger output.

## Broadcast Setup

Create one app or package-owned global `let log` near the app or package's composition root, using destinations that match its diagnostics needs.

For local console output plus in-memory support export, define one app or package-owned
global logger:

```swift
import Broadcast

public let sessionLogger = SessionLogger()

public let log = Log(
	destinations: [
		ConsoleLogger(subsystem: "com.example.app", category: "logs"),
		sessionLogger
	]
)
```

Use `public` when the logger lives in an app-specific logging module; omit it
when the logger is only needed inside one app target.

This keeps call-sites short while preserving one shared destination graph:

```swift
log.info(.event, "App launched", category: .startup)
```

Keep destination references global too when the app or package needs them later. For
example, `sessionLogger` should remain accessible to the support-export flow if
the app exposes `sessionLogger.logs()` or `sessionLogger.records()`.

When a SwiftUI app wants the logger in view code, expose the same shared logger
through SwiftUI's modern `@Entry` environment syntax. The environment should point
at the app's global logger, not a separate SwiftUI-only logger.

```swift
import Broadcast
import SwiftUI

extension EnvironmentValues {
	@Entry var log: Log = ExampleApp.log
}

struct ReminderListView: View {
	@Environment(\.log) private var log

	var body: some View {
		Button("Sync") {
			self.log.info(.action, "Started sync", category: "Sync")
		}
	}
}
```

For deterministic tests, inject a fixed date provider:

```swift
let logger = SessionLogger(
	dateProvider: Log.DateProvider { Date(timeIntervalSince1970: 0) }
)
```

Use `.timestamp` when exported logs should render Unix timestamp seconds instead
of the default ISO-8601 timestamp, not as the default deterministic-test strategy.

For custom timestamp output, define a `Foundation.FormatStyle` where
`FormatInput == Log.Timestamp` and `FormatOutput == String`:

```swift
struct SupportTimestampFormatStyle: Foundation.FormatStyle {
	func format(_ value: Log.Timestamp) -> String {
		value.date.formatted(date: .abbreviated, time: .shortened)
	}
}

extension FormatStyle where Self == SupportTimestampFormatStyle {
	static var supportTimestamp: Self {
		Self()
	}
}

let text = Log.Timestamp.now.formatted(.supportTimestamp)
```

Use custom timestamp styles directly or inside custom destinations that own
timestamp rendering. Broadcast's concrete `SessionLogger` and `MultiSessionLogger`
currently accept the built-in `Log.Timestamp.FormatStyle` options, such as
`.default` and `.timestamp`, for logger-level timestamp configuration.

For support-log export, keep a reference to a `BufferedLoggingDestination` and expose its `logs()` output through the host app's support flow:

```swift
let exportedLogs = sessionLogger.logs()
let records = sessionLogger.records()
```

Use `records()` plus a specific record formatter when an export surface needs a
shape other than the destination's default text output:

```swift
let promptLogs = sessionLogger.records()
	.map({ $0.formatted(.tokenOptimized) })
	.joined(separator: "\n")
```

For multi-session export, use `MultiSessionLogger` only after the host app configures its persistence store. Keep persistence setup in the host app layer and pass the configured store into the logger.

Expose `Log` using the host project's existing pattern:

- App or app-specific package code: prefer one immutable app or package-scoped global `let log` for the common logging surface.
- SwiftUI apps: expose that same global logger to views with `EnvironmentValues` plus `@Entry`, or pass it through an observable dependency container or app services object when that already exists.
- UIKit/AppKit apps: use the app global directly at app-owned call-sites, and pass `Log` through coordinators, service containers, or initializers when a dependency boundary needs it.
- Server apps: expose one process/app logger where appropriate, and register or pass `Log` through the application/request dependency container when handlers and services need explicit dependencies.
- Reusable packages: accept `Log` in initializers instead of reaching for app globals, so tests can inject capturing destinations.

Avoid creating a new `Log` at every call-site. Prefer a shared instance so destinations, buffering, and export behavior stay consistent.

## Call-Site Guidance

The examples below use a hypothetical Reminders app only as a concrete reference
point. Adapt the categories and payload keys to the host app's domain.

Prefer structured logs for durable diagnostics:

```swift
log.info(
	.state,
	"Loaded reminders",
	category: "Reminders",
	payload: [
		.init(key: "result", value: "Success"),
		.init(key: "reminderCount", value: reminderCount)
	]
)
```

Keep the event message at the call-site. If many logs need the same contextual values, extract a payload builder instead of hiding the log call behind a broad wrapper:

```swift
func reminderDiagnosticsPayload(additionalPayload: [Log.Payload] = []) -> [Log.Payload] {
	additionalPayload + [
		.init(key: "title", value: reminder.title),
		.init(key: "priority", value: reminder.priority)
	]
}

log.info(
	.action,
	"Updated reminder priority",
	category: "Reminders",
	payload: reminderDiagnosticsPayload(additionalPayload: [
		.init(key: "result", value: "Success")
	])
)
```

Use plain logs for short-lived local debugging:

```swift
log.info("Created", "Reminder", 3)
```

Passing an array to `Log`, such as `log.info([a, b, c])`, logs that array as one value, matching Swift's `print` behavior. Use `log.info(a, b, c)` when the intent is multiple logged values.

## Abstraction Guardrails

Prefer direct log calls at real production action and state-transition sites:

```swift
log.info(.event, "App launched", category: .startup)
```

Do not introduce a wrapper type solely so a log call can be unit tested. A
logging wrapper is justified only when production code needs shared payload
construction, repeated event shape, dependency composition, or a real integration
boundary.

Common smells:

- `AppLifecycleLogger`, `SearchLogger`, or similar types that only forward one-line log calls.
- Tests that exist only to prove forwarding wrappers emit expected strings.
- Logger abstractions created before the feature workflow they describe exists.

Prefer testing durable pieces instead:

- Category identifiers.
- Payload helper formatting.
- Redaction behavior.
- Diagnostics export content.
- Custom destinations or formatters.
- Persistent/session log export.

## SwiftUI Lifecycle Logging

For app lifecycle logs, instrument the real SwiftUI boundaries directly:

```swift
@main
struct ExampleApp: App {
	@Environment(\.scenePhase) private var scenePhase

	init() {
		log.info(.event, "App launched", category: .startup)
	}

	var body: some Scene {
		WindowGroup {
			ContentView()
		}
		.onChange(of: self.scenePhase) { _, scenePhase in
			log.info(.state, "Scene phase changed", category: .app, payload: [.init(key: "route", value: String(describing: scenePhase))])
		}
	}
}
```

Use direct lifecycle logs unless the host app already has a production services
container that owns lifecycle instrumentation.

## Record Formatting

Broadcast uses Swift `FormatStyle` types for structured log formatting customization.

`Log` keeps call-sites ergonomic and forwards structured values to each destination.
Destinations then format those values with their `recordFormatter`. This lets
different destinations eventually render the same semantic record differently while
preserving one call-site API.

Use the default structured format directly when needed:

```swift
let record = Log.Record(
	timestamp: Log.Timestamp(Date(timeIntervalSince1970: 0)),
	level: .info,
	signal: .state,
	message: "Loaded reminders",
	category: "Reminders",
	payload: [.init(key: "result", value: "Success")]
)

let text = record.formatted(.default)
```

Broadcast ships these record formats:

- `.default`: human-readable support text, e.g. `[Info | State | Reminders] @ 1970-01-01T00:00:00Z | Loaded reminders | payload=[result=Success]`.
- `.json`: a conventional structured JSON object. Export one record per line for JSON Lines-compatible output.
- `.tokenOptimized`: compact prompt-friendly text, e.g. `t=42125 l=info s=State c=Reminders m="Loaded reminders" p.result=Success`. It uses epoch milliseconds for the record timestamp, `p.` for payload fields, epoch-millisecond date payloads, and integer millisecond duration payloads.
- `.canonicalLogLine`: Stripe-style canonical log line text with normalized keys and quoted values when needed, e.g. `[1970-01-01T00:00:00Z] canonical-log-line level=info signal=State category=Reminders message="Loaded reminders" result=Success`.

Use the type-erased formatter conveniences when configuring destinations or export
objects:

```swift
let formatter = Log.Record.Formatter.tokenOptimized
let text = formatter.format(record)
```

Create a custom record formatter by defining a Swift `FormatStyle` where
`FormatInput == Log.Record` and `FormatOutput == String`:

```swift
struct CompactRecordFormatStyle: Foundation.FormatStyle, Sendable {
	func format(_ value: Log.Record) -> String {
		var text = [
			value.signal?.identifier,
			value.category?.identifier
		]
		.compactMap({ $0 })
		.joined(separator: "/")

		if !text.isEmpty {
			text += ": "
		}

		text += value.message

		if !value.payload.isEmpty {
			text += " (\(value.payload.map({ $0.formatted(.logPayload) }).joined(separator: ", ")))"
		}

		return text
	}
}

extension FormatStyle where Self == CompactRecordFormatStyle {
	static var compactRecord: Self {
		Self()
	}
}
```

Apply a custom record formatter to a destination by wrapping it in
`Log.Record.Formatter`:

```swift
final class CompactLoggingDestination: LoggingDestination {
	var recordFormatter: Log.Record.Formatter {
		Log.Record.Formatter(.compactRecord)
	}

	func log(_ record: Log.Record) {
		let text = self.recordFormatter.format(record)
		// Write `text` to this destination.
	}
}
```

If a destination only needs Broadcast's default record shape with a different
timestamp style, use the timestamp convenience initializer instead of rebuilding
the default record format:

```swift
var recordFormatter: Log.Record.Formatter {
	Log.Record.Formatter(timestampFormatStyle: .timestamp)
}
```

Custom record formatters may use `payload.formatted(.logPayload)` when they need
Broadcast's default `key=value` payload rendering. Consumers can define their own
Swift `FormatStyle` where `FormatInput == Log.Payload` when a custom record
formatter needs a different payload shape.

When modifying Broadcast itself, keep typed payload storage separate from rendered
text fields. `Log.Payload` remains the typed semantic model. Internal text formats
can convert rendered strings into `Log.Record.KeyValuePair` values and format those
pairs with `Log.Record.KeyValueFormatStyle`:

- `.raw` preserves the key and value text and backs default payload formatting.
- `.normalized` normalizes keys and quotes ambiguous values for canonical log lines.
- `.tokenOptimized` uses normalized key-value output and escapes control characters so one record stays on one physical line.

## Structured Log Style

- Keep structured logs single-line: `[Info | State | Category] @ 2026-05-31T18:06:16Z | Message | payload=[key=value]`.
- Start messages with a capital letter.
- Make categories human-readable: `"Reminders"`, not `reminders`.
- Use stable, compact payload keys: `id`, `count`, `duration`, `result`, `reason`, `route`.
- Preserve payload order so the most important diagnostic values appear first.
- Put errors in payloads instead of interpolating them into messages.
- Include explicit result payloads for durable outcomes: success for completed operations, failure for structured error operations, and specific alternatives such as skipped, rejected, cancelled, or conflict when those are more accurate.
- Use durable structured errors for failures that explain user-visible behavior, data loss, sync, payments, routing, startup, or persistence issues.
- Do not put real user data, tokens, secrets, or realistic account identifiers into examples, tests, or documentation.
- Follow the host project's local logging style for helper names, file names, visibility, and payload grouping.
- Treat structured log calls as visual blocks: separate them from adjacent executable code with a blank line, while avoiding extra blank lines against structural boundaries such as opening braces, `case`, `catch`, and closing braces.

## Privacy Checklist

Prefer durable, low-risk metadata over raw user content:

- Log token presence such as `hasAccessToken=true`, never access token or refresh token values.
- Log search length or query category, not raw search text.
- Log counts, result, reason, route, status code, duration, and operation names.
- Log safe stable IDs only when they are useful for diagnostics and not sensitive in the host domain.
- Log scope counts, or sorted scope names only when scopes are expected support context.
- Do not log full API response bodies, profile data, payment data, contact details, device tokens, or arbitrary user-entered content.
- Use synthetic fixtures in examples and tests; never include realistic secrets or account identifiers.

For auth, search, media, sync, and account features, default to presence and
counts first. Add raw identifiers only after deciding they are safe and useful
for debugging that specific product.

## App-Specific Extensions

Create app-specific categories and payload helpers outside Broadcast:

```swift
import Broadcast

extension Log.Category {
	static let reminders: Self = "Reminders"
	static let sync: Self = "Sync"
}

extension Log.Payload {
	static func priority(_ value: String) -> Self {
		.init(key: "priority", value: value)
	}
}
```

Use typed `Log.Payload(key:value:)` initializers instead of adding global
formatting extensions on `String`, `UUID`, `Bool`, `Error`, or unrelated types.

Keep helpers close to the code that owns them. Broad concepts used across many
modules can live in a shared logging package; narrow payloads should live in the
app target or feature package that emits those logs.

Prefer typed helper factories when a payload key is part of the host app's
durable diagnostic vocabulary. Raw `.init(key:value:)` is fine for one-off local
details, but repeated keys should become helpers so spelling and value formatting
stay consistent.

## Destination Guidance

- App code should normally call `Log`, not individual destinations.
- Custom destinations conform to `LoggingDestination` by implementing `log(_ record: Log.Record)`.
- Custom destinations do not need to implement zero-argument methods like `info()`; Broadcast provides those as print-like convenience extensions.
- Custom destinations do not need to implement each level method unless they are intentionally overriding Broadcast's default record creation path.
- Custom destinations can override `recordFormatter` when they need a different structured record format.
- Custom destinations receive semantic records, so they can inspect `level`, `timestamp`, `signal`, `category`, `message`, and `payload` before formatting or exporting.
- Use `BufferedLoggingDestination` when a destination needs to export canonical records or formatted text for support, diagnostics, or other use cases where individual records are useful.

## Concurrency Guidance

- Logging destination methods are synchronous, so protect shared mutable memory synchronously.
- Prefer simple synchronous synchronization for in-memory buffers on supported platforms.
- Keep persistence integrations isolated behind the host app's appropriate actor or synchronization boundary.
- Keep logged records `Sendable` when they cross task or isolation boundaries.
- Avoid async-only destination APIs unless the host app is intentionally redesigning logging around async calls.

## Testing Guidance

When integrating Broadcast, add focused tests for the host app's logging layer:

- App-specific `Log.Category` and `Log.Payload` helpers produce expected identifiers and typed values.
- Structured logs include the intended signal, category, message, and payload order.
- Shared payload builders preserve the intended ordering of event-specific values and common context.
- Support-log export works when using a buffered destination.
- Important privacy constraints are enforced with synthetic fixtures.
- Array-as-one-value behavior is understood at `Log` call-sites if the app relies on it.
- If the host app defines custom payload, timestamp, or record `FormatStyle` implementations, test each formatter independently using normal `import Broadcast`.
- If the host app defines a custom destination `recordFormatter`, add an end-to-end test proving the destination applies `Log.Record.Formatter` and combines record formatting with any relevant timestamp or payload formatting.
- Do not add tests that only prove package names, target linkage, or forwarding wrappers. Those tests create confidence noise without protecting behavior.

Run the host project's normal test/build command. If no standard command exists,
inspect the project first and choose the least surprising validation path for
that project.
