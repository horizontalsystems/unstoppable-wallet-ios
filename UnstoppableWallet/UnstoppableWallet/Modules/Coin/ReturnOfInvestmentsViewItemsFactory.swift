import RxSwift
import RxRelay
import RxCocoa
import XRatesKit

class ReturnOfInvestmentsViewItemsFactory {

    func viewItems(info: CoinMarketInfo, diffCoinCodes: [String], currentCoinCode: String, timePeriods: [TimePeriod]) -> [[CoinPageViewModel.ReturnOfInvestmentsViewItem]] {
        var viewItems = [[CoinPageViewModel.ReturnOfInvestmentsViewItem]]()

        var coinCodes = diffCoinCodes.map { $0.lowercased() }
        if let index = coinCodes.firstIndex(of: currentCoinCode.lowercased()) {
            coinCodes.remove(at: index)
        }

        var titleRow = [CoinPageViewModel.ReturnOfInvestmentsViewItem]()
        titleRow.append(.title("coin_page.return_of_investments".localized))

        coinCodes.forEach { coinCode in
            titleRow.append(.subtitle(coinCode.uppercased()))
        }

        viewItems.append(titleRow)

        timePeriods.forEach { timePeriod in
            var row = [CoinPageViewModel.ReturnOfInvestmentsViewItem]()
            row.append(.content(timePeriod.roiTitle))

            let values = info.rateDiffs[timePeriod]

            coinCodes.forEach { coinCode in
                row.append(.value(values?[coinCode]))
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
