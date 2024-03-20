enum StatPage: String {
    case addEvmSyncSource = "add_evm_sync_source"
    case addToken = "add_token"
    case advancedSearch = "advanced_search"
    case advancedSearchResults = "advanced_search_results"
    case backupRequired = "backup_required"
    case balance
    case coinManager = "coin_manager"
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
    case manageWallets = "manage_wallets"
    case markets
    case marketOverview = "market_overview"
    case marketSearch = "market_search"
    case news
    case receiveTokenList = "receive_token_list"
    case scanQrCode = "scan_qr_code"
    case sendTokenList = "send_token_list"
    case settings
    case swap
    case switchWallet = "switch_wallet"
    case tokenBalance = "token_balance"
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
    case refresh
    case switchCount
    case switchPeriod
    case switchSortType
    case toggleBalanceHidden
    case toggleConversionCoin
    case toggleSortDirection
    case addToWatchlist
    case removeFromWatchlist
    case disableToken

    var raw: String {
        switch self {
        case let .add(entity): return "\(entity.rawValue)_add"
        case let .open(page): return "\(page.rawValue)_open"
        case let .selectTab(page): return "\(page.rawValue)_select_tab"
        case .refresh: return "refresh"
        case .switchCount: return "switch_count"
        case .switchPeriod: return "switch_period"
        case .switchSortType: return "switch_sort_type"
        case .toggleBalanceHidden: return "toggle_balance_hidden"
        case .toggleConversionCoin: return "toggle_conversion_coin"
        case .toggleSortDirection: return "toggle_sort_direction"
        case .addToWatchlist: return "add_to_watchlist"
        case .removeFromWatchlist: return "remove_from_watchlist"
        case .disableToken: return "disable_token"
        }
    }
}

enum StatParam: String {
    case categoryUid = "category_uid"
    case chainUid = "chain_uid"
    case coinUid = "coin_uid"
    case sortType = "sort_type"
}

enum StatSection: String {
    case topGainers = "top_gainers"
    case topLosers = "top_losers"
    case topPlatforms = "top_platforms"
}
