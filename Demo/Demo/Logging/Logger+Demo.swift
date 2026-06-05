import Broadcast

/// The demo app's normal shared logger.
///
/// This mirrors how an integrating app can expose one composed `Log` near its
/// composition root, while still keeping specialized destinations available for
/// feature-specific routing and support-log export.
@MainActor
let log = DemoLoggers.shared.log
