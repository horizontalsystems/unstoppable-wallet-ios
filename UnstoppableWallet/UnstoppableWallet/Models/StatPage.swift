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
    case transactionFilter = "transaction_filter"
    case transactionInfo = "transaction_info"
    case watchlist
    case widget
}

enum StatSection: String {
    case topGainers = "top_gainers"
    case topLosers = "top_losers"
    case topPlatforms = "top_platforms"
}

enum StatEvent {
    case openCategory(categoryUid: String)
    case openCoin(coinUid: String)
    case openPlatform(chainUid: String)
    case open(page: StatPage)

    case switchTab(tab: StatTab)
    case switchCount
    case switchPeriod
    case switchSortType(sortType: StatSortType)
    case toggleSortDirection

    case refresh

    case toggleBalanceHidden
    case toggleConversionCoin
    case disableToken

    case addToWatchlist(coinUid: String)
    case removeFromWatchlist(coinUid: String)

    case add(entity: StatEntity)

    var name: String {
        switch self {
        case .openCategory, .openCoin, .openPlatform, .open: return "open_page"
        case .switchTab: return "switch_tab"
        case .switchCount: return "switch_count"
        case .switchPeriod: return "switch_period"
        case .switchSortType: return "switch_sort_type"
        case .toggleSortDirection: return "toggle_sort_direction"
        case .refresh: return "refresh"
        case .toggleBalanceHidden: return "toggle_balance_hidden"
        case .toggleConversionCoin: return "toggle_conversion_coin"
        case .disableToken: return "disable_token"
        case .addToWatchlist: return "add_to_watchlist"
        case .removeFromWatchlist: return "remove_from_watchlist"
        case .add: return "add"
        }
    }

    var params: [StatParam: Any]? {
        switch self {
        case let .openCategory(categoryUid): return [.page: StatPage.coinCategory, .categoryUid: categoryUid]
        case let .openCoin(coinUid): return [.page: StatPage.coinPage, .coinUid: coinUid]
        case let .openPlatform(chainUid): return [.page: StatPage.topPlatform, .chainUid: chainUid]
        case let .open(page): return [.page: page.rawValue]
        case let .switchTab(tab): return [.tab: tab.rawValue]
        case let .switchSortType(sortType): return [.sortType: sortType.rawValue]
        case let .addToWatchlist(coinUid): return [.coinUid: coinUid]
        case let .removeFromWatchlist(coinUid): return [.coinUid: coinUid]
        case let .add(entity): return [.entity: entity.rawValue]
        default: return nil
        }
    }
}

enum StatParam: String {
    case categoryUid = "category_uid"
    case chainUid = "chain_uid"
    case coinUid = "coin_uid"
    case entity
    case page
    case sortType = "sort_type"
    case tab
}

enum StatTab: String {
    case markets, balance, transactions, settings
    case overview, news, watchlist
    case all, incoming, outgoing, swap, approve
}

enum StatSortType: String {
    case balance
    case name
    case priceChange = "price_change"
}

enum StatEntity: String {
    case evmSyncSource = "evm_sync_source"
    case token
}
