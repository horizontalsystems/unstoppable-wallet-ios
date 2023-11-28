enum MarketDiscoveryFilter: String, CaseIterable {
    case blockchains = "blockchain"
    case dexEs = "dexes"
    case lending
    case yieldAggregators = "yield_aggregators"
    case gaming
    case oracles
    case nft
    case privacy
    case storage
    case wallets
    case identity
    case scaling
    case analytics
    case yieldTokens = "yield_tokens"
    case exchangeTokens = "exchange_tokens"
    case fiatStableCoins = "stablecoins"
    case tokenizedBitcoin = "tokenized_bitcoin"
    case riskManagement = "risk_management"
    case synthetics
    case indexFunds = "index_funds"
    case predictionMarkets = "prediction_markets"
    case fundraising
    case infrastructure
}

extension MarketDiscoveryFilter {
    var icon: String {
        switch self {
        case .blockchains: return "blocks_24"
        case .dexEs: return "arrow_swap_2_24"
        case .lending: return "arrow_swap_approval_2_24"
        case .yieldAggregators: return "portfolio_24"
        case .analytics: return "markets_24"
        case .oracles: return "eye_24"
        case .gaming: return "game_24"
        case .scaling: return "scale_24"
        case .privacy: return "shield_24"
        case .exchangeTokens: return "chart_2_24"
        case .wallets: return "wallet_24"
        case .fiatStableCoins: return "usd_24"
        case .nft: return "user_24"
        case .tokenizedBitcoin: return "circle_coin_24"
        case .riskManagement: return "clipboard_24"
        case .synthetics: return "flask_24"
        case .indexFunds: return "arrow_medium_3_up_right_24"
        case .fundraising: return "download_24"
        case .predictionMarkets: return "prediction_24"
        case .infrastructure: return "settings_2_24"
        case .storage: return "storage_24"
        case .identity: return "identity_24"
        case .yieldTokens: return "yield_24"
        }
    }

    var title: String {
        "market_discovery.filter_title.\(rawValue)".localized
    }

    var description: String {
        "market_discovery.filter_description.\(rawValue)".localized
    }
}
