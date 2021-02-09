enum MarketDiscoveryFilter: String, CaseIterable {
//    case rated = "rated"
    case blockchains = "blockchain"
    case dexEs = "dexes"
    case lending = "lending"
    case privacy = "privacy"
    case scaling = "scaling"
    case oracles = "oracles"
    case predictionMarkets = "prediction_markets"
    case yieldAggregators = "yield_aggregators"
    case fiatStableCoins = "fiat_stablecoins"
    case algoStableCoins = "algo_stablecoins"
    case tokenizedBitcoin = "tokenized_bitcoin"
    case stablecoinIssuers = "stablecoin_issuers"
    case exchangeTokens = "exchange_tokens"
    case metals = "metals"
    case riskManagement = "risk_management"
    case wallets = "wallets"
    case synthetics = "synthetics"
    case indexFunds = "index_funds"
    case nft = "nft"
    case fundraising = "fundraising"
    case gaming = "gaming"
    case b2b = "b2b"
    case infrastructure = "infrastructure"
    case stakingEth2_0 = "staking_eth_2_0"
    case governance = "governance"
    case crossChain = "cross_chain"
    case computing = "computing"
}

extension MarketDiscoveryFilter {

    var icon: String {
        switch self {
//        case .rated: return "chart_24"
        case .blockchains: return "blocks_24"
        case .dexEs: return "arrow_swap_2_24"
        case .lending: return "arrow_swap_approval_2_24"
        case .privacy: return "shield_24"
        case .scaling: return "scale_24"
        case .oracles: return "eye_24"
        case .predictionMarkets: return "markets_24"
        case .yieldAggregators: return "portfolio_24"
        case .fiatStableCoins: return "usd_24"
        case .algoStableCoins: return "unordered_2_24"
        case .tokenizedBitcoin: return "circle_coin_24"
        case .stablecoinIssuers: return "app_status_24"
        case .exchangeTokens: return "chart_2_24"
        case .metals: return "metals_24"
        case .riskManagement: return "clipboard_24"
        case .wallets: return "wallet_24"
        case .synthetics: return "flask_24"
        case .indexFunds: return "arrow_medium_3_up_right_24"
        case .nft: return "user_24"
        case .fundraising: return "download_24"
        case .gaming: return "game_24"
        case .b2b: return "arrow_swap_24"
        case .infrastructure: return "settings_2_24"
        case .stakingEth2_0: return "circle_plus_24"
        case .governance: return "sort_5_24"
        case .crossChain: return "link_24"
        case .computing: return "dialpad_alt_24"
        }
    }

    var title: String {
        "market_discovery.filter_title.\(rawValue)".localized
    }

    var description: String {
        "market_discovery.filter_description.\(rawValue)".localized
    }

}
