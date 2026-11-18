enum PremiumFeature: String, Identifiable {
    case swapControl = "swap_control"
    case prioritySupport = "priority_support"

    case tokenInsights = "token_insights"
    case advancedSearch = "advanced_search"
    case tradeSignals = "trade_signals"

    var id: String {
        rawValue
    }

    static var allCases: [PremiumFeature] {
        (AppStateManager.instance.swapEnabled ? [.swapControl] : []) + [.prioritySupport, .tokenInsights, .advancedSearch, .tradeSignals]
    }

    /// The features the Premium page lists. Every case in `allCases` stays Premium-gated.
    static let listed: [PremiumFeature] = [.prioritySupport, .advancedSearch, .tradeSignals]
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

    /// Localized only for the features in `PremiumFeature.listed`.
    var title: String {
        "purchases.\(rawValue)".localized
    }

    /// Localized only for the features in `PremiumFeature.listed`.
    var description: String {
        "purchases.\(rawValue).description".localized
    }
}
