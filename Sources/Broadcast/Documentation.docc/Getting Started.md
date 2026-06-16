# Getting Started

Broadcast starts with one type: ``Log``. A ``Log`` owns one or more destinations, so every call to `log.debug`, `log.info`, `log.error`, etc. is sent to each destination.

## Create a log

```swift
import Broadcast

let consoleLogger = ConsoleLogger(subsystem: "com.example.app", category: "logs")
let sessionLogger = SessionLogger()

let log = Log(
	destinations: [
		consoleLogger,
		sessionLogger
	]
)

log.info("Started app")
log.debug("Synced", 10, "links")
```

That's it. You now have one API that writes to the console and keeps an in-memory support log you can export later.

```swift
let supportLogs = sessionLogger.logs()
```

## Log simple values

Broadcast's simple logging methods work like `print`.

```swift
log.info("Started app")
log.debug("Synced", 10, "links")
log.warn("Sync took longer than expected")
```

Passing multiple arguments logs each value independently. Passing an array logs the array as one value, matching Swift's `print` behavior.

```swift
log.info("Synced", links.count, "links")
log.info(links.map(\.id))
```

## Add a little structure

Plain strings are a good start, but structured logs give you more context when you need to debug later.

```swift
extension Log.Payload {
	static func linkCount(_ count: Int) -> Self {
		Self(key: "linkCount", value: count)
	}
}

log.info(
	.state,
	"Synced links",
	category: .sync,
	payload: [
		.linkCount(links.count)
	]
)
```

You do not need to design a perfect logging system up front. Add the context that explains what happened, then grow your vocabulary as your app needs it.

## Export buffered logs

Buffered destinations keep the records they receive, so you can export them for support, bug reports, or coding agents.

```swift
let supportLogs = sessionLogger.logs()
let records = sessionLogger.records()
```

The text output uses the destination's ``LoggingDestination/recordFormatter``. Your support log can stay readable while the underlying records stay structured.

## Inject the log

I recommend creating one shared ``Log`` so you can call `log.info(...)` everywhere and keep call-sites clean.

Broadcast is intentionally not prescriptive. Use dependency injection, the SwiftUI environment, a service container, or whatever your app already uses. The important part is that your app has one easy logging API, and destinations decide where those logs go.

Packages should accept a ``Log`` in initializers so tests can inject capturing destinations.

## Next steps

Once plain logging is in place, read <doc:Structured-Logging> to add context and <doc:Destinations-And-Export> to decide where records should go.
