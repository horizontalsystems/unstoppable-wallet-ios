enum PremiumCategory: Int, CaseIterable, Identifiable, Hashable {
    case defenseSystem
    case advancedControls
    case marketInsights

    var id: String {
        switch self {
        case .defenseSystem: return "defense_system"
        case .advancedControls: return "advanced_controls"
        case .marketInsights: return "market_insights"
        }
    }
}

enum PremiumFeature: String, CaseIterable, Identifiable {
    // defense system
    case secureSend = "secure_send"
    case scamProtection = "scam_protection"
    case swapProtection = "swap_protection"
    case robberyProtection = "robbery_protection"

    // advanced controls
    case swapControl = "swap_control"
    case prioritySupport = "priority_support"

    // market insights
    case tokenInsights = "token_insights"
    case advancedSearch = "advanced_search"
    case tradeSignals = "trade_signals"

    var id: String { rawValue }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

extension PremiumCategory {
    var features: [PremiumFeature] {
        switch self {
        case .defenseSystem: return [.secureSend, .scamProtection] + (Core.shared.appStateManager.swapEnabled ? [.swapProtection] : []) + [.robberyProtection]
        case .advancedControls: return (Core.shared.appStateManager.swapEnabled ? [.swapControl] : []) + [.prioritySupport]
        case .marketInsights: return [.tokenInsights, .advancedSearch, .tradeSignals]
        }
    }
}

// UI extensions

extension PremiumFeature {
    var icon: String {
        switch self {
        case .secureSend: return "wallet_in"
        case .scamProtection: return "radar"
        case .swapProtection: return "usd"
        case .robberyProtection: return "fraud"
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
        case .defenseSystem: return "defense_filled"
        case .advancedControls: return "plus_e_filled"
        case .marketInsights: return "market_filled"
        }
    }

    var title: String {
        "purchases.\(id)".localized
    }
}
