import MarketKit

extension PriceChangeModeManager {
    var day1Period: HsTimePeriod {
        switch priceChangeMode {
        case .hour24: .hour24
        case .day1: .day1
        }
    }

    func convert(period: HsTimePeriod) -> HsTimePeriod {
        guard [HsTimePeriod.day1, .hour24].contains(period) else {
            return period
        }

        return day1Period
    }
}
