import SwiftUI

extension Color {
	static var appBackground: Color {
		#if os(macOS)
		Color(nsColor: .windowBackgroundColor)
		#else
		Color(uiColor: .systemGroupedBackground)
		#endif
	}

	static var secondaryAppBackground: Color {
		#if os(macOS)
		Color(nsColor: .underPageBackgroundColor)
		#else
		Color(uiColor: .secondarySystemGroupedBackground)
		#endif
	}
}
