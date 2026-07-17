# Broadcast instrumentation patterns

## Contents

- Dependency placement
- Temporary facade
- Event vocabulary
- Persistent destination
- Diagnostic reasoning
- Cleanup audit

## Dependency placement

Inspect the app graph before editing manifests. Add Broadcast to the narrowest module that can observe the relevant transitions. Let higher layers call a small facade exported by that module instead of importing Broadcast throughout the app.

Check Broadcast's current `Package.swift` and release documentation before choosing a version. If the host package supports more platforms than Broadcast, condition the product dependency rather than raising the host package's deployment target solely for diagnostics. A typical SwiftPM shape is:

```swift
dependencies: [
  .package(url: "https://github.com/mergesort/Broadcast", exact: "<verified-version>"),
],
targets: [
  .target(
    name: "RelevantModule",
    dependencies: [
      .product(
        name: "Broadcast",
        package: "Broadcast",
        condition: .when(platforms: [.iOS])
      ),
    ]
  ),
]
```

Resolve the app's canonical workspace or project so its checked-in lockfile is updated. Record Broadcast's transitive pins for later cleanup.

## Temporary facade

Keep Broadcast behind one source file whose name begins with `Temporary` or clearly includes `Diagnostics`. Export only the value types needed by instrumented packages:

```swift
public enum TemporaryBroadcastDiagnostics {
  public enum Level: Sendable {
    case debug, info, warning
  }

  public enum Field: Sendable {
    case bool(String, Bool)
    case int(String, Int)
    case string(String, String?)
    case uuid(String, UUID?)
  }

  public static func event(
    _ name: String,
    level: Level = .debug,
    fields: [Field] = []
  ) {
    // Convert fields to Broadcast Log.Payload values and emit to both destinations.
  }
}
```

Use `#if canImport(Broadcast)` or a platform check when the dependency is conditional. On unsupported platforms, make the facade a no-op so diagnostics do not alter deployment targets.

Construct a Broadcast `Log` with:

- `ConsoleLogger(subsystem:category:)` for attached debugging.
- A custom `LoggingDestination` for a persistent file.
- `Log.Record.Formatter.tokenOptimized` for compact traces.

Make file writes serialized, bounded, and failure-tolerant. Never let diagnostics throw into product behavior.

## Event vocabulary

Use past-tense names for completed transitions and `-started`/`-finished` pairs for spans. Keep names stable across rebuilds.

| Boundary | Example event | Required fields |
|---|---|---|
| User intent | `variation-request-received` | context/selection IDs |
| Persistence | `result-placement-set` | context, target, selected index, stored |
| Clear/invalidation | `result-placement-cleared` | context, reason |
| Publication | `timeline-published` | model ID, item count, relevant IDs |
| Reconstruction | `variation-refresh-started` | record and item counts |
| Candidate decision | `variation-record-rejected` | context, target, explicit reason |
| UI decision | `variation-action-evaluated` | selected ID, visible, enabled, reason |

Prefer finite reason strings such as `placement-missing`, `project-mismatch`, `selected-media-not-imported-result`, or `authoritative-state-unavailable`. Log a reason on every guard path that can hide the UI.

## Persistent destination

Store the trace below Application Support using a stable relative path, for example:

```text
Library/Application Support/TemporaryDiagnostics/broadcast-trace.log
```

Create the directory lazily. Append one formatted record per line. Rotate by deleting or renaming the file before the next append when it would exceed roughly 2 MB.

Do not put secrets or personal content into the trace. Safe fields generally include UUIDs, counts, booleans, result indices, status enum values, and reason codes. Avoid prompts, filenames supplied by users, URLs, tokens, and raw errors that may embed request data.

## Diagnostic reasoning

Check these failure classes explicitly:

1. **Wrong binary:** The reproduction happened before the instrumented build was installed.
2. **Lost association:** The durable result exists, but its target or imported-media mapping was never saved or was cleared.
3. **Publication race:** Commit succeeded before the authoritative model published the new item.
4. **Identity mismatch:** UI selection uses a clip ID while reconstruction indexes by scene ID, or project/sceneline IDs changed.
5. **Stale sandbox path:** A persisted absolute Application-container URL points at an old container after reinstall/update. Rebase owned sidecar files from a stable relative identity.
6. **Over-filtering:** Candidate reconstruction silently drops records. Log a rejection reason for every filter.
7. **Rendering mismatch:** State reports visible/enabled but the control is absent; trace toolbar composition and rendering next.

When repairing legacy associations, avoid time/order guesses. Prefer a stable lineage identifier or an exact, unambiguous local-content match. Reject ambiguous matches and log why.

## Cleanup audit

Use scoped searches after removing the probe:

```sh
rg -n 'Broadcast|TemporaryBroadcastDiagnostics|broadcast-trace' .
git diff --check
git status --short
```

Inspect all `Package.swift`, Xcode package references, workspace `Package.resolved` files, and other lockfiles. Diff each affected `Package.resolved` against the pre-install baseline and revert every Broadcast-related direct or transitive pin. Preserve unrelated pre-existing lockfile edits, and remove a transitive pin only when no remaining dependency requires it.

Rebuild and test after cleanup. If device testing was used, install the final dependency-free binary so the device is not left running the diagnostic build.
