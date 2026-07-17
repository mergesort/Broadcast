# macOS adaptation

Field notes from debugging a sandboxed macOS document app (typing-lag investigation, July 2026). The core loop is unchanged; substitute these mechanics for the iOS-specific steps.

## Contents

- Platform floor and facade shape
- Build, install, launch
- Driving reproduction without a user
- Collecting evidence
- Probe distortion
- Performance-bug variant of the event vocabulary

## Platform floor and facade shape

Broadcast 1.0.0 requires macOS 15 / iOS 18. When the package under test has a lower floor (for example macOS 14), do not condition the dependency into the package at all — keep the package dependency-free and inject a sink from the app target:

```swift
// In the package (no Broadcast import, no floor change):
public enum TemporaryPerfDiagnostics {
    nonisolated(unsafe) public static var sink: ((String, [String: String]) -> Void)?

    @inline(__always)
    public static func event(_ name: String, _ fields: [String: String] = [:]) {
        sink?(name, fields)
    }

    @discardableResult
    public static func measure<T>(_ name: String, _ fields: [String: String] = [:], _ work: () -> T) -> T {
        guard sink != nil else { return work() }
        let clock = ContinuousClock()
        var result: T!
        let elapsed = clock.measure { result = work() }
        var enriched = fields
        enriched["ms"] = String(format: "%.2f", Double(elapsed.components.attoseconds) / 1e15)
        event(name, enriched)
        return result
    }
}
```

Add Broadcast only to the app target (`destinationFilters: [macOS]` in XcodeGen manifests), wrap it in `#if os(macOS) && DEBUG`, and install the sink at launch from `applicationDidFinishLaunching`. Everything stays no-op until the sink is set, so unit tests and other platforms are unaffected.

## Build, install, launch

No `devicectl`/`simctl`. The Mac is the device:

```sh
xcodebuild -project <project> -scheme <scheme> -configuration Debug \
  -destination 'platform=macOS' build
open -a "<DerivedData>/Build/Products/Debug/<App>.app" <test-document>
osascript -e 'tell application "<App>" to quit'
```

Locate the product under DerivedData (`find ~/Library/Developer/Xcode/DerivedData -name "<App>.app" -path "*Debug*"`) and check the binary's modification time to confirm you are launching the freshly instrumented build, not a stale one.

## Driving reproduction without a user

AppleScript + System Events replaces manual reproduction (host terminal needs Accessibility permission):

```applescript
tell application "System Events"
  set frontmost of process "<App>" to true  -- more reliable than `activate`
  delay 1
  tell process "<App>"
    click at {x, y}  -- screen points, i.e. pixels / 2 on Retina
  end tell
  keystroke "test input"
end tell
```

Hard-won specifics:

- **Verify input landed after every attempt.** `keystroke` can silently go nowhere (wrong frontmost app, focus not in the target view) while osascript still exits 0. Capture the screen (`screencapture -x out.png`) and read the image to confirm the typed text is visible before trusting the trace.
- A screenshot immediately after typing can catch pre-settled UI (for example, a debounced pass that has not fired yet). Wait, retype a marker string, and re-capture before concluding a behavior regressed.
- Relaunching with `open -a <app> <doc>` reopens autosaved state; account for prior test input already in the document.

## Collecting evidence

- **The trace file is the primary channel.** For a sandboxed app it lives at `~/Library/Containers/<bundle-id>/Data/Library/Application Support/<trace-file>` and is directly readable from the host — no copy step.
- **Do not rely on `log show` for probe events.** It hides debug-level messages without `--debug`, and debug-level os_log is frequently not persisted to the store at all, so even `--debug` can return nothing. Treat `ConsoleLogger` as attached-debugging convenience only.
- **Flush the trace on a timer or at low event counts, and on quit.** A flush-every-N-events design loses the tail — which is exactly where the post-reproduction events land once input stops. Losing the final restyle events to an unflushed buffer cost a full rebuild-and-rerun cycle here. `applicationWillTerminate` is a good backstop.

## Probe distortion

Logging inside a hot loop distorts what you are measuring. An event emitted per `setAttributes` call (~6,500 per keystroke) inflated the measured apply pass roughly 5× (745 ms probed vs ~130 ms honest). Emit span timings (`measure`) around phases and aggregate counts as fields (`runs=10400`); never one event per iteration of a suspected-hot loop. If a hot-path event was needed to discover a call count, delete it and re-measure before treating any surrounding numbers as real.

## Performance-bug variant of the event vocabulary

For latency bugs (vs. state-flow bugs), instrument these boundaries instead:

1. Input handler entered/exited (the number the user feels) — for typing, the `textDidChange` handler.
2. Each phase of the expensive pipeline as a `measure` span (parse, apply, layout), with size fields (`chars`, `runs`).
3. Suspected-redundant work sites as cheap comparison events (for example `updateNSView` logging `themeUnchanged=true/false`) to kill or confirm churn theories.
4. Anything scheduled per input event (debounced writers, snapshots) as scheduled/executed pairs.

Benchmark the suspect algorithm in isolation (`swift test` with a probe test) before blaming it: here the markdown styler measured linear and within 3% of the pre-rewrite styler, which redirected the investigation to the AppKit layer (per-call editing transactions amplified by whole-document `fixAttributes`) — the actual root cause.
