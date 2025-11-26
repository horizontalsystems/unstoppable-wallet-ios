enum PremiumCategory: Int, CaseIterable, Identifiable, Hashable {
    case defenseSystem
    case marketInsights
    case vip

    var id: String {
        switch self {
        case .defenseSystem: return "defense_system"
        case .marketInsights: return "market_insights"
        case .vip: return "vip"
        }
    }
}

enum PremiumFeature: String, CaseIterable, Identifiable {
    // defense
    case secureSend = "secure_send"
    case scamProtection = "scam_protection"
    case lossProtection = "loss_protection"
    case robberyProtection = "robbery_protection"
    // insights
    case tokenInsights = "token_insights"
    case advancedSearch = "advanced_search"
    case tradeSignals = "trade_signals"
    // vip
    case vipSupport = "vip_support"

    var id: String { rawValue }
}

extension PremiumCategory {
    var features: [PremiumFeature] {
        switch self {
        case .defenseSystem: return [.secureSend, .scamProtection, .lossProtection, .robberyProtection]
        case .marketInsights: return [.tokenInsights, .advancedSearch, .tradeSignals]
        case .vip: return [.vipSupport]
        }
    }
}

// UI extensions

extension PremiumFeature {
    var icon: String {
        switch self {
        case .secureSend: return "wallet_in"
        case .scamProtection: return "radar"
        case .lossProtection: return "usd"
        case .robberyProtection: return "fraud"
        case .tokenInsights: return "binocular"
        case .advancedSearch: return "search"
        case .tradeSignals: return "bell"
        case .vipSupport: return "message"
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
        case .marketInsights: return "market_filled"
        case .vip: return "heart_filled"
        }
    }

    var title: String {
        "purchases.\(id)".localized
    }
}
