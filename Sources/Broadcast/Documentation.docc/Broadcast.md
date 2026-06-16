# ``Broadcast``

Composable logging for Swift apps, servers, and coding agents.

## Overview

Broadcast is a structured logging library for Swift apps and servers that feels as lightweight as `print`, but gives every log enough structure to help you solve real production issues.

Broadcast turns simple logs like `log.info("Started app")` into a trail of actions and state that can be sent to your console, saved to support logs, or optimized for coding agents — all at once.

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

log.info(
	.state,
	"Synced links",
	category: .sync,
	payload: [
		.result(.success),
		.linkCount(links.count)
	]
)
```

Broadcast is already running in production in [Plinky](https://plinky.app), where it's helped Codex track down bugs and race conditions I'd been chasing for over a year. By handing hand an agent thousands of structured logs you take the guesswork out of debugging, and instead a coding agent can trace through and debug problems with far less help from you — often completely autonomously.

By integrating Broadcast from day one you'll give coding agents provide agents with the feedback loop they need while they work, leading to fewer bugs and less time reviewing slop.

## Topics

### Essentials

- <doc:Getting-Started>
- <doc:Structured-Logging>
- ``Log``
- ``LoggingDestination``
- ``BufferedLoggingDestination``

### Destinations

- <doc:Destinations-And-Export>
- ``ConsoleLogger``
- ``SessionLogger``
- ``MultiSessionLogger``

### Formatting

- <doc:Formatting-Records>
- ``Log/Record``
- ``Log/Record/Formatter``
- ``Log/Record/FormatStyle``

### Testing

- <doc:Testing-Logging>
- ``Log/DateProvider``
