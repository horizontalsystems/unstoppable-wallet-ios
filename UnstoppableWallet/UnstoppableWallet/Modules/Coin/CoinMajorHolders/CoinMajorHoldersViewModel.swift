import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinMajorHoldersViewModel {
    private let service: CoinMajorHoldersService
    private let disposeBag = DisposeBag()

    private let stateViewItemRelay = BehaviorRelay<StateViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: CoinMajorHoldersService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<[TokenHolder]>) {
        switch state {
        case .loading:
            stateViewItemRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .completed(let holders):
            stateViewItemRelay.accept(stateViewItem(holders: holders))
            loadingRelay.accept(false)
            errorRelay.accept(nil)
        case .failed:
            stateViewItemRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func stateViewItem(holders: [TokenHolder]) -> StateViewItem {
        let viewItems = holders.enumerated().map { index, item in
            ViewItem(order: "\(index + 1)", percent: "\(item.share)%", address: item.address)
        }

        let totalPercentDecimal = holders.map { $0.share }.reduce(0, +)
        let totalPercent = NSDecimalNumber(decimal: totalPercentDecimal).doubleValue

        let chartPercents: [Double] = [totalPercent, 100.0 - totalPercent]
        let percent = "\(Int(round(totalPercent)))%"

        return StateViewItem(chartPercents: chartPercents, percent: percent, viewItems: viewItems)
    }

}

extension CoinMajorHoldersViewModel {

    var stateViewItemDriver: Driver<StateViewItem?> {
        stateViewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension CoinMajorHoldersViewModel {

    struct ViewItem {
        let order: String
        let percent: String
        let address: String
    }

    struct StateViewItem {
        let chartPercents: [Double]
        let percent: String
        let viewItems: [ViewItem]
    }

}
