enum MarketDiscoveryFilter: String, CaseIterable {
    case rated = "rated"
    case blockchains = "blockchain"
    case privacy = "privacy"
    case scaling = "scaling"
    case infrastructure = "infrastructure"
    case riskManagement = "risk_management_and_hedging"
    case oracles = "oracles"
    case predictionMarkets = "prediction_markets"
    case defiAggregators = "defi_aggregators"
    case dexEs = "dexes"
    case synthetics = "synthetics"
    case metals = "metals"
    case lending = "lending"
    case gamingNVr = "gaming_and_vr"
    case fundraising = "fundraising"
    case internetOfThings = "iot"
    case b2b = "b2b"
    case nft = "nft"
    case wallets = "wallets"
    case staking = "staking"
    case fiatStableCoins = "fiat_stablecoins"
    case tokenizedBitcoin = "tokenized_bitcoin"
    case algoStableCoins = "algo_stablecoins"
}

extension MarketDiscoveryFilter {

    var icon: String {
        switch self {
        case .rated: return "chart_24"
        case .blockchains: return "blocks_24"
        case .privacy: return "shield_24"
        case .scaling: return "scale_24"
        case .infrastructure: return "settings_2_24"
        case .riskManagement: return "clipboard_24"
        case .oracles: return "eye_2_24"
        case .predictionMarkets: return "markets_24"
        case .defiAggregators: return "portfolio_24"
        case .dexEs: return "arrow_swap_2_24"
        case .synthetics: return "flask_24"
        case .metals: return "metals_24"
        case .lending: return "arrow_swap_approval_2_24"
        case .gamingNVr: return "game_24"
        case .fundraising: return "download_24"
        case .internetOfThings: return "globe_24"
        case .b2b: return "arrow_swap_24"
        case .nft: return "user_24"
        case .wallets: return "wallet_24"
        case .staking: return "circle_plus_24"
        case .fiatStableCoins: return "usd_24"
        case .tokenizedBitcoin: return "circle_coin_24"
        case .algoStableCoins: return "unordered_24"
        }
    }

    var title: String {
        "market_discovery.filter_title.\(rawValue)".localized
    }

    var description: String {
        "market_discovery.filter_description.\(rawValue)".localized
    }

}
