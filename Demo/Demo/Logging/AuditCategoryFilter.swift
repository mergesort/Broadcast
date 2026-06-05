import Broadcast

enum AuditCategoryFilter: String, CaseIterable, Identifiable {
	case all = "All"
	case operations = "Operations"
	case pipeline = "Pipeline"
	case traffic = "Traffic"
	case workers = "Workers"
	case metrics = "Metrics"
	case incidents = "Incidents"
	case storage = "Storage"
	case export = "Export"

	static var categoryCases: [Self] {
		Self.allCases.filter { $0 != .all }
	}

	var id: Self {
		self
	}

	var title: String {
		self.rawValue
	}

	func matches(_ record: Log.Record) -> Bool {
		switch self {
		case .all:
			true
		case .metrics:
			record.signal == .metric || record.category?.identifier == self.rawValue
		default:
			record.category?.identifier == self.rawValue
		}
	}
}
