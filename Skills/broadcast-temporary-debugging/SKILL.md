---
name: broadcast-temporary-debugging
description: Temporarily instrument Swift, iOS, and macOS apps with mergesort/Broadcast to diagnose state-flow, persistence, selection, UI-visibility, and main-thread latency bugs end to end. Use when the user says "debug this issue using Broadcast," asks for temporary structured Broadcast tracing, or wants Codex to install Broadcast, build/install/launch an app on a simulator, physical device, or the local Mac, collect and analyze persistent traces, fix and verify the root cause, and then completely remove Broadcast and all temporary diagnostics before handoff. Do not use for permanent logging infrastructure.
---

# Debug Apps with Broadcast

Use Broadcast as a disposable diagnostic probe. Continue through diagnosis, fix, device verification, and dependency removal unless the user pauses the loop.

## Enforce the temporary-tool contract

- Add an explicit final plan step: **Remove Broadcast and all temporary diagnostics**.
- Capture the initial working-tree state before edits. Preserve unrelated and pre-existing changes.
- Track every manifest, lockfile pin, source file, and call site added for diagnostics.
- Never call the task complete while Broadcast or the temporary facade remains in shipping source.
- If the user pauses before cleanup, state prominently: `Broadcast is still installed and must not ship.`
- Keep captured traces outside the repository unless the user requests otherwise.

## Establish the baseline

1. Read all repository instructions, including local overrides and Swift/Xcode rules.
2. Inspect `git status --short`, relevant diffs, package manifests, deployment targets, schemes, bundle IDs, and connected devices.
3. Record the exact symptom, reproduction steps, selected object, expected UI state, and approximate timestamp.
4. Map the data flow from initiating event through persistence, publication, selection, eligibility, and rendering.
5. Identify the branch predicates that can suppress the expected result.

Do not ask the user to reproduce until the instrumented binary has actually been installed and launched. Record build and installation timestamps to distinguish old-binary evidence from new-binary evidence.

## Design and install the probe

Read [references/instrumentation-patterns.md](references/instrumentation-patterns.md) completely before adding Broadcast.

1. Verify the current Broadcast release, Swift tools version, and platform minimums from its official repository.
2. Choose the narrowest package or target that spans the relevant data flow. Do not add Broadcast to unrelated packages.
3. Prefer an exact temporary version so the diagnostic build is reproducible.
4. Use platform-conditional dependencies when a shared package supports platforms below Broadcast's minimum.
5. Resolve dependencies and inspect every new direct and transitive lockfile pin.
6. Add one clearly temporary facade, such as `TemporaryBroadcastDiagnostics`, so cleanup has a single seam.

## Instrument the whole decision path

Emit structured events at these boundaries:

1. Request or user action received.
2. Context and target resolved.
3. Durable record write started and finished.
4. Result imported or transformed.
5. Placement or association set, changed, or cleared.
6. Authoritative model/state published.
7. Reconstruction or refresh started and finished.
8. Each candidate accepted, rejected, or deferred.
9. Final UI action evaluated, including `visible`, `enabled`, and a stable reason.

Log stable IDs, counts, booleans, enum names, timestamps, and explicit rejection reasons. Do not log prompts, auth tokens, request URLs, user content, or full filesystem paths. Make diagnostic failures non-fatal.

Persist a bounded trace under Application Support and also log to the console. Rotate or truncate the trace around 2 MB. Prefer Broadcast's token-optimized formatter for compact device pulls.

## Build and deploy the instrumented binary

1. Run the narrowest relevant unit tests and formatting checks.
2. Build the real app for the requested destination.
3. Derive the built `.app` path from build settings or build output; do not assume a stale DerivedData path.
4. Install over the existing bundle to preserve app data when appropriate.
5. Launch the app and confirm installation succeeded before requesting reproduction.

For a physical device, adapt this sequence:

```sh
xcrun devicectl list devices
xcodebuild build -project <project> -scheme <scheme> -configuration Debug \
  -destination 'platform=iOS,id=<device-id>'
xcrun devicectl device install app --device <device-id> <app-path>
xcrun devicectl device process launch --device <device-id> <bundle-id>
```

Use `simctl` equivalents for a simulator. Keep the user updated during long builds.

For a macOS app, read [references/macos-adaptation.md](references/macos-adaptation.md): build with `-destination 'platform=macOS'`, launch with `open -a`, drive reproduction with AppleScript/System Events (verifying input landed via screenshots), and read the sandboxed trace directly from `~/Library/Containers/<bundle-id>/Data/Library/Application Support/` — `log show` cannot be trusted for debug-level probe events even with `--debug`.

## Reproduce and collect evidence

Give one precise instruction: reproduce once, leave the app on the failing screen, and reply when done. Avoid requiring a costly generation if selecting an existing object exercises the same path.

Pull the persistent trace with the app-data-container domain:

```sh
xcrun devicectl device copy from \
  --device <device-id> \
  --domain-type appDataContainer \
  --domain-identifier <bundle-id> \
  --source '<relative-trace-path>' \
  --destination <unique-local-path>
```

Also pull any durable sidecar, database, or JSON record referenced by the trace. Redact sensitive fields before printing them.

Correlate events by context ID, project ID, target ID, media ID, and timestamp. Follow the first divergence backward to its writer. Verify filesystem claims directly rather than trusting persisted absolute URLs, especially after app updates or reinstalls.

## Fix and prove the root cause

1. Implement the smallest durable fix in production code, separate from the probe.
2. Add a regression test reproducing the failed state transition or persistence boundary.
3. Run focused tests, then build and reinstall the instrumented app.
4. Reproduce again and require the trace to show the repaired association and expected final UI decision.
5. Inspect the durable record after verification to prove the fix survives relaunch.

Do not stop at `visible=true` if the control still does not render; continue into the rendering layer.

## Remove Broadcast before handoff

Perform cleanup only after the fix is verified, but always perform it before declaring completion:

1. Save the useful trace outside the repository.
2. Remove every temporary event call and the diagnostic facade/file destination.
3. Remove Broadcast product dependencies and package declarations from every manifest/project.
4. Resolve packages again. Revert every `Package.resolved` change introduced by installing Broadcast, including Broadcast and now-unused transitive pins, without disturbing pre-existing lockfile changes or dependencies still used elsewhere. Compare against the recorded baseline instead of deleting the whole lockfile.
5. Search the repository for `Broadcast`, the facade name, diagnostic event prefixes, and the trace filename.
6. Review the final diff against the captured baseline. Remove only diagnostic changes; preserve the production fix, regression tests, and unrelated user work.
7. Run formatting, `git diff --check`, focused tests, and a dependency-free app build.
8. Install and launch the final dependency-free binary on the same destination when device verification was part of the loop.

Report cleanup explicitly. If any Broadcast reference remains intentionally, identify the exact file and do not describe the work as complete.

## Definition of done

Finish only when all are true:

- The trace explains the original failure.
- A production fix and regression test exist.
- The fixed behavior is verified on the relevant destination.
- Broadcast, its temporary facade, trace calls, and every related `Package.resolved` change are removed.
- The final dependency-free build and tests pass.
