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
