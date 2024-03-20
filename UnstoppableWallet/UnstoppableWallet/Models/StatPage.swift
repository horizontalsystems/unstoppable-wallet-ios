enum StatPage: String {
    case addEvmSyncSource = "add_evm_sync_source"
    case addToken = "add_token"
    case advancedSearch = "advanced_search"
    case advancedSearchResults = "advanced_search_results"
    case balance
    case coinPage = "coin_page"
    case coinCategory = "coin_category"
    case coinRank = "coin_rank"
    case externalMarketPair = "external_market_pair"
    case externalNews = "external_news"
    case globalMetricsMarketCap = "global_metrics_market_cap"
    case globalMetricsVolume = "global_metrics_volume"
    case globalMetricsDefiCap = "global_metrics_defi_cap"
    case globalMetricsTvlInDefi = "global_metrics_tvl_in_defi"
    case main
    case markets
    case marketOverview = "market_overview"
    case marketSearch = "market_search"
    case news
    case settings
    case switchWallet = "switch_wallet"
    case topCoins = "top_coins"
    case topMarketPairs = "top_market_pairs"
    case topNftCollections = "top_nft_collections"
    case topPlatform = "top_platform"
    case topPlatforms = "top_platforms"
    case tokenPage = "token_page"
    case transactions
    case transactionInfo = "transaction_info"
    case watchlist
    case widget
}

enum StatEntity: String {
    case evmSyncSource = "evm_sync_source"
    case token
}

enum StatEvent {
    case add(entity: StatEntity)
    case open(page: StatPage)
    case selectTab(page: StatPage)
    case switchCount
    case switchPeriod
    case toggleSortDirection
    case addToWatchlist
    case removeFromWatchlist

    var raw: String {
        switch self {
        case let .add(entity): return "\(entity.rawValue)_add"
        case let .open(page): return "\(page.rawValue)_open"
        case let .selectTab(page): return "\(page.rawValue)_select_tab"
        case .switchCount: return "switch_count"
        case .switchPeriod: return "switch_period"
        case .toggleSortDirection: return "toggle_sort_direction"
        case .addToWatchlist: return "add_to_watchlist"
        case .removeFromWatchlist: return "remove_from_watchlist"
        }
    }
}

enum StatParam: String {
    case categoryUid = "category_uid"
    case chainUid = "chain_uid"
    case coinUid = "coin_uid"
}

enum StatSection: String {
    case topGainers = "top_gainers"
    case topLosers = "top_losers"
    case topPlatforms = "top_platforms"
}
