import XRatesKit

class MarketDataSourceFactory {

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
