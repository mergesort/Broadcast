# Structured Logging

Structured logs make future debugging sessions less painful.

## Describing Your Event

Logging plain strings is useful for quick local debugging, but structured logs provide the context you need to fix complicated problems. We can do so by using typed values such as ``Log/Signal``, ``Log/Category`` and ``Log/Payload`` to add context for future debugging sessions.

```swift
log.info(
	.state,
	"Synced links",
	category: .sync,
	payload: [
		.result(.success),
		.linkCount(links.count)
	]
)

extension Log.Payload {
	static func result(_ result: Result) -> Self {
		Self(key: "result", value: result)
	}

	static func linkCount(_ count: Int) -> Self {
		Self(key: "linkCount", value: count)
	}
}
```

## Signals, Categories, and Payloads

### Signals

``Log/Signal`` describes what happened:

- ``Log/Signal/action`` for something the app attempted or completed.
- ``Log/Signal/state`` for a meaningful state transition or decision.
- ``Log/Signal/event`` for noteworthy occurrences.
- ``Log/Signal/metric`` for measured values.
- ``Log/Signal/diagnostic`` for support-oriented detail.

### Categories

``Log/Category`` describes the part of your app the event belongs to.

```swift
extension Log.Category {
	static let sync: Self = "Sync"
	static let account: Self = "Account"
	static let paywall: Self = "Paywall"
}
```

Here we've added a few custom categories for our app to make it easier to track events from sync, account, and paywall code.

### Payloads

``Log/Payload`` is where most of our useful context will live. We can add identifiers, counts, dates, durations, outcomes, errors, and anything else that helps explain what happened.

```swift
log.error(
	.diagnostic,
	"Failed to refresh account",
	category: .account,
	payload: [
		.id(account.id),
		.error(error),
		.init(key: "attempt", value: attempt),
	]
)
```

Broadcast supports typed payload values for strings, booleans, integers, UUIDs, URLs, dates, errors, and durations.

## Build App-Specific Helpers

When a payload key shows up in more than one place, I suggest turning it into a small app-specific property or function.

```swift
extension Log.Category {
	static let sync: Self = "Sync"
}

extension Log.Payload {
	static func accountID(_ id: UUID) -> Self {
		Self(key: "accountID", value: id)
	}

	static func linkCount(_ count: Int) -> Self {
		Self(key: "linkCount", value: count)
	}
}

log.info(
	.action,
	"Finished account sync",
	category: .sync,
	payload: [
		.accountID(account.id),
		.linkCount(links.count),
		.init(key: "duration", duration: syncDuration)
	]
)
```

## Safe and Secure Payloads

Never log secrets, access tokens, refresh tokens, passwords, payment information, or other sensitive user data. For more details, I suggest reading [Keeping Secrets Out Of Logs](https://allan.reyes.sh/posts/keeping-secrets-out-of-logs).
