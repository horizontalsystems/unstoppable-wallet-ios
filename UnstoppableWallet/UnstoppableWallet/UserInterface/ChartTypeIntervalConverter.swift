import MarketKit

class ChartTypeIntervalConverter {
    private static let day = 24
    private static let month = 24 * 30

    static func convert(chartType: ChartType) -> Int {
        switch chartType {
        case .today: return 6
        case .day: return 6
        case .week: return 2 * day
        case .week2: return 3 * day
        case .month: return 6 * day
        case .monthByDay: return 6 * day
        case .month3: return 18 * day
        case .halfYear: return month
        case .year: return 2 * month
        case .year2: return 4 * month
        }
    }

}
