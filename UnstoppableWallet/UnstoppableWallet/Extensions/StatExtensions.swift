import MarketKit

extension HsTimePeriod {
    var statPeriod: StatPeriod {
        switch self {
        case .day1: return .day1
        case .week1: return .week1
        case .week2: return .week2
        case .month1: return .month1
        case .month3: return .month3
        case .month6: return .month6
        case .year1: return .year1
        case .year2: return .year2
        case .year5: return .year5
        }
    }
}

extension MarketEtfViewModel.TimePeriod {
    var statPeriod: StatPeriod {
        switch self {
        case .all: return .all
        case let .period(timePeriod): return timePeriod.statPeriod
        }
    }
}

extension HsPeriodType {
    var statPeriod: StatPeriod {
        switch self {
        case let .byPeriod(period): return period.statPeriod
        case let .byCustomPoints(period, _): return period.statPeriod
        case .byStartTime: return .all
        }
    }
}

extension MainModule.Tab {
    var statTab: StatTab {
        switch self {
        case .markets: return .markets
        case .balance: return .balance
        case .transactions: return .transactions
        case .settings: return .settings
        }
    }
}

extension MarketModule.Tab {
    var statTab: StatTab {
        switch self {
        case .coins: return .coins
        case .news: return .news
        case .pairs: return .pairs
        case .platforms: return .platforms
        case .watchlist: return .watchlist
        }
    }
}

extension MarketModule.TabOld {
    var statTab: StatTab {
        switch self {
        case .overview: return .overview
        case .posts: return .news
        case .watchlist: return .watchlist
        }
    }
}

extension CoinPageModule.Tab {
    var statTab: StatTab {
        switch self {
        case .overview: return .overview
        case .analytics: return .analytics
        case .markets: return .markets
        }
    }
}

extension TransactionTypeFilter {
    var statTab: StatTab {
        switch self {
        case .all: return .all
        case .incoming: return .incoming
        case .outgoing: return .outgoing
        case .swap: return .swap
        case .approve: return .approve
        }
    }
}

extension WalletModule.SortType {
    var statSortType: StatSortType {
        switch self {
        case .balance: return .balance
        case .name: return .name
        case .percentGrowth: return .priceChange
        }
    }
}

extension MarketGlobalModule.MetricsType {
    var statPage: StatPage {
        switch self {
        case .totalMarketCap: return .globalMetricsMarketCap
        case .volume24h: return .globalMetricsVolume
        case .defiCap: return .globalMetricsDefiCap
        case .tvlInDefi: return .globalMetricsTvlInDefi
        }
    }
}

extension CoinProChartModule.ProChartType {
    var statPage: StatPage {
        switch self {
        case .cexVolume: return .coinAnalyticsCexVolume
        case .dexVolume: return .coinAnalyticsDexVolume
        case .dexLiquidity: return .coinAnalyticsDexLiquidity
        case .activeAddresses: return .coinAnalyticsActiveAddresses
        case .txCount: return .coinAnalyticsTxCount
        case .tvl: return .coinAnalyticsTvl
        }
    }
}

extension CoinRankModule.RankType {
    var statRankType: StatPage {
        switch self {
        case .cexVolume: return .coinRankCexVolume
        case .dexVolume: return .coinRankDexVolume
        case .dexLiquidity: return .coinRankDexLiquidity
        case .address: return .coinRankAddress
        case .txCount: return .coinRankTxCount
        case .holders: return .coinRankHolders
        case .fee: return .coinRankFee
        case .revenue: return .coinRankRevenue
        }
    }
}

extension MarketModule.Top {
    var statMarketTop: StatMarketTop {
        switch self {
        case .top100: return .top100
        case .top200: return .top200
        case .top250: return .top250
        case .top300: return .top300
        case .top500: return .top500
        case .top1000: return .top1000
        case .top1500: return .top1500
        }
    }
}

extension MarketModule.MarketTop {
    var statMarketTop: StatMarketTop {
        switch self {
        case .top100: return .top100
        case .top200: return .top200
        case .top300: return .top300
        }
    }
}

extension MarketModule.PriceChangeType {
    var statPeriod: StatPeriod {
        switch self {
        case .day: return .day1
        case .week: return .week1
        case .week2: return .week2
        case .month: return .month1
        case .month6: return .month6
        case .year: return .year1
        }
    }
}

extension MarketModule.MarketField {
    var statField: StatField {
        switch self {
        case .marketCap: return .marketCap
        case .volume: return .volume
        case .price: return .price
        }
    }
}

extension MarketModule.MarketPlatformField {
    var statTvlChain: String {
        switch self {
        case .all: return "all"
        default: return chain
        }
    }
}

extension MarketModule.SortBy {
    var statSortType: StatSortType {
        switch self {
        case .highestCap: return .highestCap
        case .lowestCap: return .lowestCap
        case .highestVolume: return .highestVolume
        case .lowestVolume: return .lowestVolume
        case .gainers: return .topGainers
        case .losers: return .topLosers
        }
    }
}

extension WatchlistSortBy {
    var statSortType: StatSortType {
        switch self {
        case .manual: return .manual
        case .highestCap: return .highestCap
        case .lowestCap: return .lowestCap
        case .gainers: return .topGainers
        case .losers: return .topLosers
        }
    }
}

extension MarketModule.SortOrder {
    var statVolumeSortType: StatSortType {
        switch self {
        case .asc: return .lowestVolume
        case .desc: return .highestVolume
        }
    }
}

extension MarketModule.MarketTvlField {
    var statField: String {
        switch self {
        case .value: return "currency"
        case .diff: return "percent"
        }
    }
}

extension MarketTvlViewModel.DiffType {
    var statField: String {
        switch self {
        case .percent: return "percent"
        case .currencyValue: return "currency"
        }
    }
}

extension MarketTvlViewModel.Platforms {
    var statPlatform: String {
        switch self {
        case .all: return "all"
        case .ethereum: return "Ethereum"
        case .solana: return "Solana"
        case .binance: return "Binance"
        case .avalanche: return "Avalanche"
        case .terra: return "Terra"
        case .fantom: return "Fantom"
        case .arbitrum: return "Arbitrum"
        case .polygon: return "Polygon"
        }
    }
}

extension MarketEtfViewModel.SortBy {
    var statSortBy: StatSortType {
        switch self {
        case .highestAssets: return .highestAssets
        case .lowestAssets: return .lowestAssets
        case .inflow: return .inflow
        case .outflow: return .outflow
        }
    }
}

extension WatchlistTimePeriod {
    var statPeriod: StatPeriod {
        switch self {
        case .day1: return .day1
        case .week1: return .week1
        case .month1: return .month1
        case .month3: return .month3
        }
    }
}

extension MarketModule.SortingField {
    var statSortType: StatSortType {
        switch self {
        case .highestCap: return .highestCap
        case .lowestCap: return .lowestCap
        case .highestVolume: return .highestVolume
        case .lowestVolume: return .lowestVolume
        case .topGainers: return .topGainers
        case .topLosers: return .topLosers
        }
    }
}

extension MarketTopPlatformsModule.SortType {
    var statSortType: StatSortType {
        switch self {
        case .highestCap: return .highestCap
        case .lowestCap: return .lowestCap
        case .topGainers: return .topGainers
        case .topLosers: return .topLosers
        }
    }
}

extension LinkType {
    var statPage: StatPage {
        switch self {
        case .guide: return .guide
        case .website: return .externalCoinWebsite
        case .whitepaper: return .externalCoinWhitePaper
        case .twitter: return .externalTwitter
        case .telegram: return .externalTelegram
        case .reddit: return .externalReddit
        case .github: return .externalGithub
        }
    }
}
