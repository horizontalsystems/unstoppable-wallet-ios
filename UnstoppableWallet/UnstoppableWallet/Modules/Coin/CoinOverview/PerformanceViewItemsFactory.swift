import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class PerformanceViewItemsFactory {

    func viewItems(info: MarketInfoOverview) -> [[CoinOverviewViewModel.PerformanceViewItem]] {
        var viewItems = [[CoinOverviewViewModel.PerformanceViewItem]]()

        var titleRow = [CoinOverviewViewModel.PerformanceViewItem]()
        titleRow.append(.title("coin_page.return_of_investments".localized))

        var timePeriods = [TimePeriod]()
        for (_, changes) in info.performance {
            for timePeriod in changes.keys {
                if !timePeriods.contains(timePeriod) {
                    timePeriods.append(timePeriod)
                    titleRow.append(.subtitle(timePeriod.roiTitle))
                }
            }
        }

        viewItems.append(titleRow)

        info.performance.forEach { (coinCode, changes) in
            var row = [CoinOverviewViewModel.PerformanceViewItem]()
            row.append(.content("vs \(coinCode.uppercased())"))

            timePeriods.forEach { timePeriod in
                row.append(.value(changes[timePeriod]))
            }
            viewItems.append(row)
        }

        return viewItems
    }

}

extension TimePeriod {

    var roiTitle: String {
        switch self {
        case .all: return "n/a".localized
        case .hour1: return "coin_page.roi.hour1".localized
        case .dayStart: return "n/a".localized
        case .hour24: return "coin_page.roi.hour24".localized
        case .day7: return "coin_page.roi.day7".localized
        case .day14: return "coin_page.roi.day14".localized
        case .day30: return "coin_page.roi.day30".localized
        case .day200: return "coin_page.roi.day200".localized
        case .year1: return "coin_page.roi.year1".localized
        }
    }

}
