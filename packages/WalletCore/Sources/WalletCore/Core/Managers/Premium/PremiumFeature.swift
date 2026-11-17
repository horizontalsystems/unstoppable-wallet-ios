enum PremiumCategory: Int, CaseIterable, Identifiable, Hashable {
    case advancedControls
    case marketInsights

    var id: String {
        switch self {
        case .advancedControls: return "advanced_controls"
        case .marketInsights: return "market_insights"
        }
    }
}

enum PremiumFeature: String, Identifiable {
    // advanced controls
    case swapControl = "swap_control"
    case prioritySupport = "priority_support"

    // market insights
    case tokenInsights = "token_insights"
    case advancedSearch = "advanced_search"
    case tradeSignals = "trade_signals"

    var id: String {
        rawValue
    }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    static var allCases: [PremiumFeature] {
        (AppStateManager.instance.swapEnabled ? [.swapControl] : []) + [.prioritySupport, .tokenInsights, .advancedSearch, .tradeSignals]
    }
}

extension PremiumCategory {
    var features: [PremiumFeature] {
        switch self {
        case .advancedControls: return (AppStateManager.instance.swapEnabled ? [.swapControl] : []) + [.prioritySupport]
        case .marketInsights: return [.tokenInsights, .advancedSearch, .tradeSignals]
        }
    }
}

// UI extensions

extension PremiumFeature {
    var icon: String {
        switch self {
        case .swapControl: return "swap_e"
        case .prioritySupport: return "message"
        case .tokenInsights: return "binocular"
        case .advancedSearch: return "search"
        case .tradeSignals: return "bell"
        }
    }

    var title: String {
        "purchases.\(rawValue)".localized
    }

    var description: String {
        "purchases.\(rawValue).description".localized
    }

    var info: String {
        "purchases.\(rawValue).info".localized
    }
}

extension PremiumCategory {
    var icon: String {
        switch self {
        case .advancedControls: return "plus_e_filled"
        case .marketInsights: return "market_filled"
        }
    }

    var title: String {
        "purchases.\(id)".localized
    }
}
