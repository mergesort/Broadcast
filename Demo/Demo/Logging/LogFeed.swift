enum LogFeed: String, CaseIterable, Identifiable {
	case live
	case metrics
	case audit

	var id: Self {
		self
	}

	var title: String {
		switch self {
		case .live: "Live"
		case .metrics: "Metrics"
		case .audit: "Audit"
		}
	}
}
