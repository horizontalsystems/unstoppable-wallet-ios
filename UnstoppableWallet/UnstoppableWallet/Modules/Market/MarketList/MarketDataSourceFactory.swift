import XRatesKit

class MarketDataSourceFactory {

    func marketListItem(rank: Int, topMarket: TopMarket) -> MarketListDataSource.Item {
        MarketListDataSource.Item(
                rank: rank,
                coinCode: topMarket.coin.code,
                coinName: topMarket.coin.title,
                marketCap: topMarket.marketInfo.marketCap,
                price: topMarket.marketInfo.rate,
                diff: topMarket.marketInfo.rateDiffPeriod,
                volume: topMarket.marketInfo.volume)
    }

    func marketListPeriod(period: MarketListDataSource.Period) -> TimePeriod {
        switch period {
        case .hour: return .hour1
        case .day: return .hour24
        case .week: return .day7
        case .month: return .day30
        case .year: return .year1
        case .dayStart: return .dayStart
        }
    }

}
