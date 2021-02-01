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
        switch self {
        case .rated: return "market_discovery.filter_rated.title".localized
        case .blockchains: return "market_discovery.filter_blockchains.title".localized
        case .privacy: return "market_discovery.filter_privacy.title".localized
        case .scaling: return "market_discovery.filter_scaling.title".localized
        case .infrastructure: return "market_discovery.filter_infrastructure.title".localized
        case .riskManagement: return "market_discovery.filter_risk_management.title".localized
        case .oracles: return "market_discovery.filter_oracles.title".localized
        case .predictionMarkets: return "market_discovery.filter_prediction_markets.title".localized
        case .defiAggregators: return "market_discovery.filter_defi_aggregators.title".localized
        case .dexEs: return "market_discovery.filter_dexes.title".localized
        case .synthetics: return "market_discovery.filter_synthetics.title".localized
        case .metals: return "market_discovery.filter_metals.title".localized
        case .lending: return "market_discovery.filter_lending.title".localized
        case .gamingNVr: return "market_discovery.filter_gaming_and_vr.title".localized
        case .fundraising: return "market_discovery.filter_fundraising.title".localized
        case .internetOfThings: return "market_discovery.filter_internet_of_things.title".localized
        case .b2b: return "market_discovery.filter_b2b.title".localized
        case .nft: return "market_discovery.filter_nft.title".localized
        case .wallets: return "market_discovery.filter_wallets.title".localized
        case .staking: return "market_discovery.filter_staking.title".localized
        case .fiatStableCoins: return "market_discovery.filter_fiat_stable_coins.title".localized
        case .tokenizedBitcoin: return "market_discovery.filter_tokenized_bitcoin.title".localized
        case .algoStableCoins: return "market_discovery.filter_algo_stable_coins.title".localized
        }
    }

    var description: String {
        switch self {
        case .rated: return "market_discovery.filter_rated.description".localized
        case .blockchains: return "market_discovery.filter_blockchains.description".localized
        case .privacy: return "market_discovery.filter_privacy.description".localized
        case .scaling: return "market_discovery.filter_scaling.description".localized
        case .infrastructure: return "market_discovery.filter_infrastructure.description".localized
        case .riskManagement: return "market_discovery.filter_risk_management.description".localized
        case .oracles: return "market_discovery.filter_oracles.description".localized
        case .predictionMarkets: return "market_discovery.filter_prediction_markets.description".localized
        case .defiAggregators: return "market_discovery.filter_defi_aggregators.description".localized
        case .dexEs: return "market_discovery.filter_dexes.description".localized
        case .synthetics: return "market_discovery.filter_synthetics.description".localized
        case .metals: return "market_discovery.filter_metals.description".localized
        case .lending: return "market_discovery.filter_lending.description".localized
        case .gamingNVr: return "market_discovery.filter_gaming_and_vr.description".localized
        case .fundraising: return "market_discovery.filter_fundraising.description".localized
        case .internetOfThings: return "market_discovery.filter_internet_of_things.description".localized
        case .b2b: return "market_discovery.filter_b2b.description".localized
        case .nft: return "market_discovery.filter_nft.description".localized
        case .wallets: return "market_discovery.filter_wallets.description".localized
        case .staking: return "market_discovery.filter_staking.description".localized
        case .fiatStableCoins: return "market_discovery.filter_fiat_stable_coins.description".localized
        case .tokenizedBitcoin: return "market_discovery.filter_tokenized_bitcoin.description".localized
        case .algoStableCoins: return "market_discovery.filter_algo_stable_coins.description".localized
        }
    }

}
