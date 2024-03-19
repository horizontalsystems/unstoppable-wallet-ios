enum StatPage: String {
    case advancedSearchResults = "advanced_search_results"
    case coinPage = "coin_page"
    case coinCategory = "coin_category"
    case coinRank = "coin_rank"
    case globalMetricsMarketCap = "global_metrics_market_cap"
    case globalMetricsVolume = "global_metrics_volume"
    case globalMetricsDefiCap = "global_metrics_defi_cap"
    case globalMetricsTvlInDefi = "global_metrics_tvl_in_defi"
    case marketOverview = "market_overview"
    case marketSearch = "market_search"
    case topCoins = "top_coins"
    case topMarketPairs = "top_market_pairs"
    case topNftCollections = "top_nft_collections"
    case topPlatform = "top_platform"
    case topPlatforms = "top_platforms"
    case tokenPage = "token_page"
    case transactionInfo = "transaction_info"
    case watchlist
    case widget
}

enum StatEvent: String {
    case coinOpen = "coin_open"
}

enum StatParam: String {
    case coinUid = "coin_uid"
}

enum StatSection: String {
    case topGainers = "top_gainers"
    case topLosers = "top_losers"
}
