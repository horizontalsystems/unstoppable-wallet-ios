import MarketKit

class ChartIntervalConverter {
    private static let day = 24
    private static let month = 24 * 30

    static func convert(interval: HsTimePeriod) -> Int {
        switch interval {
        case .day1: return 6
        case .week1: return 2 * day
        case .week2: return 3 * day
        case .month1: return 6 * day
        case .month3: return 18 * day
        case .month6: return month
        case .year1: return 2 * month
        }
    }

}
