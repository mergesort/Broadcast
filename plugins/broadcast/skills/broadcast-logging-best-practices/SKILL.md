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
4. Inject that `Log` through the host app's existing dependency injection pattern.
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

Create one shared `Log` near the app's composition root, using destinations that match the app's diagnostics needs.

For local console output plus in-memory support export:

```swift
import Broadcast

let sessionLogger = SessionLogger()
let log = Log(
	destinations: [
		ConsoleLogger(subsystem: "com.example.app", category: "logs"),
		sessionLogger
	]
)
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

Inject `Log` using the host project's existing pattern:

- SwiftUI apps: put `Log` in an environment value, observable dependency container, or app services object.
- UIKit/AppKit apps: pass `Log` through coordinators, service containers, or initializers.
- Server apps: register `Log` in the application/request dependency container and pass it into handlers or services.
- Packages: accept `Log` in initializers instead of reaching for globals, so tests can inject capturing destinations.

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
