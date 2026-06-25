# Structured Logging

Structured logs make future debugging sessions less painful.

## Describing Your Event

Logging plain strings is useful for quick local debugging, but structured logs provide the context you need to fix complicated problems. We can do so by using typed values like ``Log/Signal``, ``Log/Category`` and ``Log/Payload`` to add context for future debugging sessions.

```swift
log.info(
	.state,
	"Synced links",
	category: .sync,
	payload: [
		.result("Success"),
		.linkCount(links.count)
	]
)

extension Log.Payload {
	static func result(_ result: String) -> Self {
		Self.string("result", result)
	}

	static func linkCount(_ count: Int) -> Self {
		Self.int("linkCount", count)
	}
}
```

## Signals, Categories, and Payloads

### Signals

``Log/Signal`` describes what happened.

- ``Log/Signal/action`` for something the app attempted or completed.
- ``Log/Signal/state`` for a meaningful state transition or decision.
- ``Log/Signal/event`` for noteworthy occurrences.
- ``Log/Signal/metric`` for measured values.
- ``Log/Signal/diagnostic`` for support-oriented detail.

### Categories

``Log/Category`` describes what part or subsystem of your app this log is tied to.

```swift
extension Log.Category {
	static let sync: Self = "Sync"
	static let account: Self = "Account"
	static let paywall: Self = "Paywall"
}
```

Here we've added a few custom categories for our app to make it easier to track events from our sync, account, and paywall code.

### Payloads

``Log/Payload`` is where most of our log's context will live. We can add identifiers, counts, dates, durations, outcomes, errors, and anything else that helps explain what happened.

```swift
log.error(
	.diagnostic,
	"Failed to refresh account",
	category: .account,
	payload: [
		.id(account.id),
		.error(error),
		.int("attempt", attempt),
	]
)
```

Broadcast supports typed payload values for strings, booleans, integers, UUIDs, URLs, dates, errors, and durations out of the box.

## Build App-Specific Helpers

When a payload key shows up in more than one place, I suggest turning it into a small app or package-specific property or function.

```swift
extension Log.Category {
	static let sync: Self = "Sync"
}

extension Log.Payload {
	static func accountID(_ id: UUID) -> Self {
		Self.uuid("accountID", id)
	}

	static func linkCount(_ count: Int) -> Self {
		Self.int("linkCount", count)
	}
}

log.info(
	.action,
	"Finished account sync",
	category: .sync,
	payload: [
		.accountID(account.id),
		.linkCount(links.count),
		.duration(seconds: syncDuration)
	]
)
```

## Safe and Secure Payloads

Never log secrets, access tokens, refresh tokens, passwords, payment information, or other sensitive user data. For more details, I suggest reading [Keeping Secrets Out Of Logs](https://allan.reyes.sh/posts/keeping-secrets-out-of-logs).
