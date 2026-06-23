# Full watchOS Support for Broadcast Logging

Status as of 2026-06-19 · branch `feat/broadcast-logging`

> **Decision (2026-06-19): deferred.** Broadcast's **structured logging** is now
> fully integrated into the comms path (typed `Log.Signal`/`Log.Payload`
> vocabulary, a structured `SundialKitStream` event bridge, and capturing-destination
> tests — see SundialKitStream's `WATCH_COMMS_RELIABILITY.md`). The
> **`MultiSessionLogger`** persistence work described below remains **out of scope**:
> the live `make logs` capture (in-memory `SessionLogger` + token-optimized stdout)
> is sufficient for current debugging. Revisit only if a bug evades live capture
> because it only manifests across a relaunch boundary (post-crash / field report).
> The rest of this document remains the plan for that future phase.

Goal: restore Broadcast's **`MultiSessionLogger`** (cross-launch, persisted logs)
so the full structured-logging stack — including history that survives relaunches
— works on watchOS, not just iOS/macOS.

---

## Where we are

Broadcast is integrated and building on **both watchOS and iOS** today, with one
deliberate omission.

**Working now:**
- `AppLog` (`Packages/AtLeastKit/Sources/AtLeastApp/AppLog.swift`) — a Broadcast
  `Log` fanning to `ConsoleLogger` (OSLog), a token-optimized stdout mirror, and
  an in-memory `SessionLogger`.
- SundialKitStream send/receive diagnostics bridged in via `SundialStreamLog`.
- watchOS app + iOS app build clean via the Tuist workspace; 74 + 81 unit tests pass.

**Vendored fork:** Broadcast lives at `Packages/Broadcast` as a `git subrepo`
(`git@github.com:brightdigit/Broadcast.git` @ `atleast-beta.6`), referenced as a
local-path SPM package.

**What's trimmed (the gap):** `MultiSessionLogger` and its `Boutique` dependency
were removed from the fork. That's the **only** missing piece — there is no
cross-launch / persisted log buffer on any platform right now.

---

## Why it was trimmed

`MultiSessionLogger` is the sole consumer of this chain:

```
Broadcast → Boutique → Bodega → SQLite.swift
                    └→ swift-collections (OrderedCollections)
```

Three of those packages **do not declare a watchOS platform** in their
`Package.swift`:

| Package | Declared platforms | watchOS? |
|---|---|---|
| Boutique | `.iOS(.v17), .macOS(.v14)` | ❌ |
| Bodega | `.iOS(.v17), .macOS(.v14)` | ❌ |
| swift-collections | (no explicit watchOS floor) | ❌ |
| SQLite.swift | `.watchOS(.v4)` → 9.0 | ✅ |

With no watchOS declaration, SPM/Xcode assign a **default watchOS deployment
target of 8.0**, below the SDK floor of 9.0. The build then fails:

```
error: 'WATCHOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported
versions is 9.0 to 27.0.x (in target 'Bodega' / 'OrderedCollections' / ...)
error: 'SQLite-product' requires minimum platform version 9.0 ... but this
target supports 8.0 (in target 'Bodega')
```

It is a **deployment-target/manifest mismatch, not a code-compatibility problem.**
We could not fix it from the app side because Tuist's
`PackageSettings.baseSettings` (the documented deployment-target override) is
**ignored** under this project's `Project.swift` `packages:` SPM integration mode.

---

## Key finding: the code is almost certainly watchOS-compatible

A scan of the dependency sources found **no genuine watchOS blockers**:

- **Boutique** — no `UIKit` / `AppKit` / `WatchKit` imports. Only
  `#if os(macOS)` guards (macOS-specific keychain in `SecurelyStoredValue.swift`).
  watchOS would take the same non-macOS path as iOS.
- **Bodega** — no UI-framework imports. Only `#if os(macOS)` guards in
  `FileManager.Directory.swift`. Uses `FileManager` + SQLite, both available on
  watchOS.
- **swift-collections** — pure portable Swift (Apple package; builds on watchOS).
- **SQLite.swift** — already declares watchOS 9+.

So the work is mostly **declaring `.watchOS(...)` in three manifests and
confirming a clean compile** — not porting code off unavailable APIs.

⚠️ Not yet verified: an actual watchOS *compile + link* of Boutique/Bodega, and
that SQLite-backed persistence behaves on a real watch (sandbox container paths,
write availability when the app is backgrounded). These are the real risks.

---

## What we need to do

### Recommended: fork the manifests, then re-enable persistence

1. **Fork + patch the three packages** (mirror the Broadcast pattern — private
   `brightdigit/*` forks, branch `atleast-beta.6`):
   - `brightdigit/Boutique` — add `.watchOS(.v11)` (Mutex/Observation floor),
     `.tvOS`, `.visionOS` to `platforms`.
   - `brightdigit/Bodega` — add the same.
   - `swift-collections` — Apple's; prefer pinning a version that declares
     watchOS if available, otherwise fork to add it. (Pure-Swift, lowest risk.)
   - Pick a watchOS floor consistent with the app. The hard floor is **9.0**
     (SDK minimum); to use `Synchronization.Mutex` / modern Observation it's
     **11.0**. AtLeast targets watchOS 26, so 11.0 is safe and simplest.

2. **Vendor them as subrepos** under `Packages/` (Boutique, Bodega,
   swift-collections), same as `Packages/Broadcast`, so there are no remote
   clones and the platform patches are pinned. Each becomes a local-path SPM
   package.

3. **Un-trim the Broadcast fork** (`Packages/Broadcast`):
   - Restore `Sources/Broadcast/Loggers/MultiSessionLogger.swift` (+ its test).
   - Re-add the `Boutique` dependency in `Package.swift`, pointing at the
     **local vendored Boutique** (`.package(path: "../Boutique")`), not the
     remote.

4. **Wire `MultiSessionLogger` into `AppLog`** as a fourth destination, behind a
   `Boutique.Store<Log.Record>` (`SQLiteStorageEngine`). Note its init is
   `@MainActor` and async (`try await Store(...)`), so add an async bootstrap at
   app launch rather than in the synchronous `AppLog.shared` initializer — e.g.
   `AppLog.enablePersistence()` called from the App's `.task`.

### Alternative: upstream the platform declarations

Boutique/Bodega are mergesort's, and Broadcast is explicitly "built for coding
agents" — adding watchOS to those manifests is a small, friendly PR. If accepted,
we drop the forks and depend on tagged releases. Slower (depends on review/release
cadence) but the cleanest long-term. Could be done in parallel with the fork.

### Alternative: keep trimmed, persist ourselves

If Boutique/Bodega turn out to misbehave on watchOS, implement a minimal custom
`LoggingDestination` that appends token-optimized records to a file in the app
group container (no Boutique/SQLite). More code, but zero third-party watchOS
risk and full control. Fallback only.

---

## Verification plan

1. Build each forked package standalone for watchOS:
   `xcodebuild -scheme Boutique -destination 'generic/platform=watchOS' build`
   (with the same `WATCHOS_DEPLOYMENT_TARGET` override used earlier to confirm
   the *source* compiles before trusting the manifest).
2. `tuist generate` + build `AtLeast-watchOS` — confirm no 8.0 deployment errors.
3. On-device (`make logs`): start a session, force-quit, relaunch, and confirm
   `MultiSessionLogger` surfaces prior-launch records. This is the real proof —
   watch sandbox + SQLite persistence behaving across launches.
4. Re-run `swift test` for the Broadcast fork (restore `MultiSessionLogger.Tests`).

---

## Open questions

- **Floor:** 9.0 (max compatibility) vs 11.0 (Mutex/modern Observation, matches
  app)? Recommend 11.0 — AtLeast is watchOS 26 anyway.
- **Upstream vs fork:** open PRs to mergesort/Boutique + Bodega, or stay on
  brightdigit forks indefinitely? Forks unblock us now; upstreaming is the clean
  end state.
- **swift-collections:** does a current tagged release already declare watchOS?
  Check before forking Apple's package — a version bump may be all that's needed.
- **App group container:** which container does the watch `Store` write to, and
  is it writable while the extended-runtime session is active / app backgrounded?

---

## Pointers

- Trimmed fork manifest: `Packages/Broadcast/Package.swift`
- Logger seam: `Packages/AtLeastKit/Sources/AtLeastApp/AppLog.swift`
- Bridge: `Packages/SundialKitStream/Sources/SundialKitStream/SundialStreamLog.swift`
- Removed in the trim (to restore): `MultiSessionLogger.swift`,
  `MultiSessionLogger.Tests.swift`
- Background on the deployment-target failure: this repo's git history for
  commit `2e4cacf` (build(broadcast): … trim MultiSessionLogger …).
