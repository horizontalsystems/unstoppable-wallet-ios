enum StatPage: String {
    case aboutApp = "about_app"
    case academy
    case addEvmSyncSource = "add_evm_sync_source"
    case addToken = "add_token"
    case advancedSearch = "advanced_search"
    case advancedSearchResults = "advanced_search_results"
    case appearance
    case backupRequired = "backup_required"
    case backupManager = "backup_manager"
    case balance
    case baseCurrency = "base_currency"
    case blockchainSettings = "blockchain_settings"
    case coinAnalyticsCexVolume = "coin_analytics_cex_volume"
    case coinAnalyticsDexVolume = "coin_analytics_dex_volume"
    case coinAnalyticsDexLiquidity = "coin_analytics_dex_liquidity"
    case coinAnalyticsActiveAddresses = "coin_analytics_active_addresses"
    case coinAnalyticsTxCount = "coin_analytics_tx_count"
    case coinAnalyticsTvl = "coin_analytics_tvl"
    case coinManager = "coin_manager"
    case coinPage = "coin_page"
    case coinCategory = "coin_category"
    case coinRank = "coin_rank"
    case contacts
    case contactUs = "contact_us"
    case donate
    case externalCompanyWebsite = "external_company_website"
    case externalMarketPair = "external_market_pair"
    case externalNews = "external_news"
    case externalTelegram = "external_telegram"
    case externalTwitter = "external_twitter"
    case faq
    case globalMetricsMarketCap = "global_metrics_market_cap"
    case globalMetricsVolume = "global_metrics_volume"
    case globalMetricsDefiCap = "global_metrics_defi_cap"
    case globalMetricsTvlInDefi = "global_metrics_tvl_in_defi"
    case importWallet = "import_wallet"
    case language
    case main
    case manageWallets = "manage_wallets"
    case markets
    case marketOverview = "market_overview"
    case marketSearch = "market_search"
    case news
    case newWallet = "new_wallet"
    case rateUs = "rate_us"
    case receiveTokenList = "receive_token_list"
    case scanQrCode = "scan_qr_code"
    case security
    case sendTokenList = "send_token_list"
    case settings
    case swap
    case switchWallet = "switch_wallet"
    case tellFriends = "tell_friends"
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
    case walletConnect = "wallet_connect"
    case watchlist
    case watchWallet = "watch_wallet"
    case widget
}

enum StatSection: String {
    case popular
    case recent
    case searchResults = "search_results"

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
    case switchMarketTop(marketTop: StatMarketTop)
    case switchPeriod(period: StatPeriod)
    case switchField(field: StatField)
    case switchSortType(sortType: StatSortType)
    case switchChartPeriod(period: StatPeriod)
    case switchTvlChain(chain: String)
    case toggleSortDirection
    case toggleTvlField

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
        case .switchMarketTop: return "switch_market_top"
        case .switchPeriod: return "switch_period"
        case .switchField: return "switch_field"
        case .switchSortType: return "switch_sort_type"
        case .switchChartPeriod: return "switch_chart_period"
        case .switchTvlChain: return "switch_tvl_platform"
        case .toggleSortDirection: return "toggle_sort_direction"
        case .toggleTvlField: return "toggle_tvl_field"
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
        case let .switchMarketTop(marketTop): return [.marketTop: marketTop.rawValue]
        case let .switchPeriod(period): return [.period: period.rawValue]
        case let .switchField(field): return [.field: field.rawValue]
        case let .switchSortType(sortType): return [.sortType: sortType.rawValue]
        case let .switchChartPeriod(period): return [.period: period.rawValue]
        case let .switchTvlChain(chain): return [.tvlChain: chain]
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
    case field
    case marketTop = "market_top"
    case page
    case period
    case sortType = "sort_type"
    case tab
    case tvlChain = "tvl_chain"
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

enum StatPeriod: String {
    case day1 = "1d"
    case week1 = "1w"
    case week2 = "2w"
    case month1 = "1m"
    case month3 = "3m"
    case month6 = "6m"
    case year1 = "1y"
    case year2 = "2y"
    case year5 = "5y"
    case all
}

enum StatField: String {
    case marketCap = "market_cap"
    case volume
    case price
}

enum StatMarketTop: String {
    case top100
    case top200
    case top300
}

enum StatEntity: String {
    case evmSyncSource = "evm_sync_source"
    case token
}
