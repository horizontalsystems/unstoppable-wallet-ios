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
        "aave"
    }

    var title: String {
        switch self {
        case .rated: return "market_discovery.filter_rated".localized
        case .blockchains: return "market_discovery.filter_blockchains".localized
        case .privacy: return "market_discovery.filter_privacy".localized
        case .scaling: return "market_discovery.filter_scaling".localized
        case .infrastructure: return "market_discovery.filter_infrastructure".localized
        case .riskManagement: return "market_discovery.filter_risk_management".localized
        case .oracles: return "market_discovery.filter_oracles".localized
        case .predictionMarkets: return "market_discovery.filter_prediction_markets".localized
        case .defiAggregators: return "market_discovery.filter_defi_aggregators".localized
        case .dexEs: return "market_discovery.filter_dexes".localized
        case .synthetics: return "market_discovery.filter_synthetics".localized
        case .metals: return "market_discovery.filter_metals".localized
        case .lending: return "market_discovery.filter_lending".localized
        case .gamingNVr: return "market_discovery.filter_gaming_and_vr".localized
        case .fundraising: return "market_discovery.filter_fundraising".localized
        case .internetOfThings: return "market_discovery.filter_internet_of_things".localized
        case .b2b: return "market_discovery.filter_b2b".localized
        case .nft: return "market_discovery.filter_nft".localized
        case .wallets: return "market_discovery.filter_wallets".localized
        case .staking: return "market_discovery.filter_staking".localized
        case .fiatStableCoins: return "market_discovery.filter_fiat_stable_coins".localized
        case .tokenizedBitcoin: return "market_discovery.filter_tokenized_bitcoin".localized
        case .algoStableCoins: return "market_discovery.filter_algo_stable_coins".localized
        }
    }

    var description: String {
        "Ratings follow a specialized rating system to represent the quality and risk"
    }

}
