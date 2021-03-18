import RxSwift
import RxRelay
import RxCocoa
import XRatesKit

class CoinReturnOfInvestmentsViewModel {
    private let service: CoinPageService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<[[ViewItem]]>(value: [])

    init(service: CoinPageService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<CoinMarketInfo>) {
        guard case let .completed(data) = state else {
            viewItemRelay.accept([])
            return
        }

        var viewItems = [[ViewItem]]()

        var titleRow = [ViewItem]()
        var coinCodes = service.diffCoinCodes.map { $0.lowercased() }
        titleRow.append(.title("coin_page.return_of_investments".localized))

        if let index = coinCodes.firstIndex(of: service.coinCode.lowercased()) {
            coinCodes.remove(at: index)
        }

        coinCodes.forEach { coinCode in
            titleRow.append(.subtitle(coinCode.uppercased()))
        }

        viewItems.append(titleRow)

        CoinPageService.timePeriods.forEach { timePeriod in
            var row = [ViewItem]()
            row.append(.content(timePeriod.roiTitle))

            let values = data.rateDiffs[timePeriod]

            coinCodes.forEach { coinCode in
                row.append(.value(values?[coinCode]))
            }
            viewItems.append(row)
        }

        viewItemRelay.accept(viewItems)
    }

}

extension CoinReturnOfInvestmentsViewModel {

    var viewItemDriver: Driver<[[ViewItem]]> {
        viewItemRelay.asDriver()
    }

}

extension CoinReturnOfInvestmentsViewModel {

    enum ViewItem {
        case title(String)
        case subtitle(String)
        case content(String)
        case value(Decimal?)
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
