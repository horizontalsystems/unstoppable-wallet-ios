import Foundation
import MarketKit

enum MarketModule {
    enum SortBy: String, CaseIterable {
        case highestCap
        case lowestCap
        case gainers
        case losers
        case highestVolume
        case lowestVolume

        var title: String {
            switch self {
            case .highestCap: return "market.sort_by.highest_cap".localized
            case .lowestCap: return "market.sort_by.lowest_cap".localized
            case .gainers: return "market.sort_by.gainers".localized
            case .losers: return "market.sort_by.losers".localized
            case .highestVolume: return "market.sort_by.highest_volume".localized
            case .lowestVolume: return "market.sort_by.lowest_volume".localized
            }
        }
    }

    enum SortOrder {
        case asc
        case desc

        mutating func toggle() {
            switch self {
            case .asc: self = .desc
            case .desc: self = .asc
            }
        }

        var isAsc: Bool { self == .asc }
    }

    enum Top: Int, CaseIterable, Identifiable {
        static let `default` = Top.top100

        case top100 = 100
        case top200 = 200
        case top300 = 300
        case top500 = 500
        case top1000 = 1000
        case top1500 = 1500
        case top2000 = 2000
        case top2500 = 2500

        var title: String {
            "market.top_coins".localized("\(rawValue)")
        }

        var description: String {
            let result = "market.advanced_search.top.m_cap".localized + " "
            switch self {
            case .top100: return result + "market.advanced_search.top.more_1_b".localized
            case .top200: return result + "market.advanced_search.top.more_500_m".localized
            case .top300: return result + "market.advanced_search.top.more_250_m".localized
            case .top500: return result + "market.advanced_search.top.more_100_m".localized
            case .top1000: return result + "market.advanced_search.top.more_25_m".localized
            case .top1500: return result + "market.advanced_search.top.more_10_m".localized
            case .top2000: return result + "market.advanced_search.top.more_5_m".localized
            case .top2500: return result + "market.advanced_search.top.more_1_m".localized
            }
        }

        var id: Int {
            rawValue
        }
    }

    enum Tab: String, CaseIterable {
        case coins
        case watchlist
        case news
        case platforms
        case pairs
        case sectors

        var title: String {
            switch self {
            case .coins: return "market.tab.coins".localized
            case .watchlist: return "market.tab.watchlist".localized
            case .news: return "market.tab.news".localized
            case .platforms: return "market.tab.platforms".localized
            case .pairs: return "market.tab.pairs".localized
            case .sectors: return "market.tab.sectors".localized
            }
        }
    }
}

extension MarketKit.MarketInfo {
    func priceChangeValue(timePeriod: HsTimePeriod) -> Decimal? {
        switch timePeriod {
        case .hour24: return priceChange24h
        case .day1: return priceChange1d
        case .week1: return priceChange7d
        case .week2: return priceChange14d
        case .month1: return priceChange30d
        case .month3: return priceChange90d
        case .month6: return priceChange200d
        case .year1: return priceChange1y
        default: return nil
        }
    }

    func priceChangeValue(timePeriod: WatchlistTimePeriod) -> Decimal? {
        switch timePeriod {
        case .hour24: return priceChange24h
        case .day1: return priceChange1d
        case .week1: return priceChange7d
        case .month1: return priceChange30d
        case .month3: return priceChange90d
        }
    }
}

extension MarketKit.DefiCoin {
    func tvlChangeValue(timePeriod: HsTimePeriod) -> Decimal? {
        switch timePeriod {
        case .day1: return tvlChange1d
        case .week1: return tvlChange1w
        case .week2: return tvlChange2w
        case .month1: return tvlChange1m
        case .month3: return tvlChange6m
        case .month6: return tvlChange6m
        case .year1: return tvlChange1y
        default: return nil
        }
    }
}

extension [MarketKit.MarketInfo] {
    func sorted(sortBy: WatchlistSortBy, timePeriod: WatchlistTimePeriod) -> [MarketKit.MarketInfo] {
        switch sortBy {
        case .manual: return self
        case .highestCap: return sorted { $0.marketCap ?? 0 > $1.marketCap ?? 0 }
        case .lowestCap: return sorted { $0.marketCap ?? 0 < $1.marketCap ?? 0 }
        case .gainers, .losers: return sorted {
                guard let lhsPriceChange = $0.priceChangeValue(timePeriod: timePeriod) else {
                    return false
                }
                guard let rhsPriceChange = $1.priceChangeValue(timePeriod: timePeriod) else {
                    return true
                }

                return sortBy == .gainers ? lhsPriceChange > rhsPriceChange : lhsPriceChange < rhsPriceChange
            }
        }
    }

    func sorted(sortBy: MarketModule.SortBy, timePeriod: HsTimePeriod) -> [MarketKit.MarketInfo] {
        switch sortBy {
        case .highestCap: return sorted { $0.marketCap ?? 0 > $1.marketCap ?? 0 }
        case .lowestCap: return sorted { $0.marketCap ?? 0 < $1.marketCap ?? 0 }
        case .highestVolume: return sorted { $0.totalVolume ?? 0 > $1.totalVolume ?? 0 }
        case .lowestVolume: return sorted { $0.totalVolume ?? 0 < $1.totalVolume ?? 0 }
        case .gainers, .losers: return sorted {
                guard let lhsPriceChange = $0.priceChangeValue(timePeriod: timePeriod) else {
                    return false
                }
                guard let rhsPriceChange = $1.priceChangeValue(timePeriod: timePeriod) else {
                    return true
                }

                return sortBy == .gainers ? lhsPriceChange > rhsPriceChange : lhsPriceChange < rhsPriceChange
            }
        }
    }
}

extension [MarketKit.TopPlatform] {
    func sorted(sortBy: MarketModule.SortBy, timePeriod: HsTimePeriod) -> [TopPlatform] {
        sorted { lhsPlatform, rhsPlatform in
            let lhsCap = lhsPlatform.marketCap
            let rhsCap = rhsPlatform.marketCap

            let lhsChange = lhsPlatform.changes[timePeriod]
            let rhsChange = rhsPlatform.changes[timePeriod]

            switch sortBy {
            case .highestCap, .lowestCap:
                guard let lhsCap else {
                    return true
                }
                guard let rhsCap else {
                    return false
                }

                return sortBy == .highestCap ? lhsCap > rhsCap : lhsCap < rhsCap
            case .gainers, .losers:
                guard let lhsChange else {
                    return false
                }
                guard let rhsChange else {
                    return true
                }

                return sortBy == .gainers ? lhsChange > rhsChange : lhsChange < rhsChange
            default: return true
            }
        }
    }
}

extension HsTimePeriod {
    var title: String {
        switch self {
        case .hour24: return "market.time_period.1d".localized
        default: return "market.time_period.\(rawValue)".localized
        }
    }

    var shortTitle: String {
        switch self {
        case .hour24: return "market.time_period.1d.short".localized
        default: return "market.time_period.\(rawValue).short".localized
        }
    }

    init?(_ periodType: HsPeriodType) {
        guard case let .byPeriod(timePeriod) = periodType else {
            return nil
        }
        self = timePeriod
    }
}

extension WatchlistTimePeriod {
    var title: String {
        switch self {
        case .hour24: return "market.time_period.1d".localized
        default: return "market.time_period.\(rawValue)".localized
        }
    }

    var shortTitle: String {
        switch self {
        case .hour24: return "market.time_period.1d.short".localized
        default: return "market.time_period.\(rawValue).short".localized
        }
    }
}

extension WatchlistSortBy {
    var title: String {
        switch self {
        case .manual: return "market.sort_by.manual".localized
        case .highestCap: return "market.sort_by.highest_cap".localized
        case .lowestCap: return "market.sort_by.lowest_cap".localized
        case .gainers: return "market.sort_by.gainers".localized
        case .losers: return "market.sort_by.losers".localized
        }
    }
}
