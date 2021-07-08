import RxSwift
import RxRelay
import RxCocoa

class CoinMajorHoldersViewModel {
    private let service: CoinMajorHoldersService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)

    init(service: CoinMajorHoldersService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: CoinMajorHoldersService.State) {
        switch state {
        case .loading: stateRelay.accept(.loading)
        case .failed: stateRelay.accept(.failed)
        case .loaded(let items):
            let viewItems = items.enumerated().map { index, item in
                ViewItem(order: "\(index + 1)", percent: "\(item.share)%", address: item.address)
            }

            let totalPercentDecimal = items.map { $0.share }.reduce(0, +)
            let totalPercent = NSDecimalNumber(decimal: totalPercentDecimal).doubleValue

            let chartPercents: [Double] = [totalPercent, 100.0 - totalPercent]
            let percent = "\(Int(round(totalPercent)))%"

            let stateViewItem = StateViewItem(chartPercents: chartPercents, percent: percent, viewItems: viewItems)
            stateRelay.accept(.loaded(stateViewItem: stateViewItem))
        }
    }

}

extension CoinMajorHoldersViewModel {

    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

}

extension CoinMajorHoldersViewModel {

    enum State {
        case loading
        case failed
        case loaded(stateViewItem: StateViewItem)
    }

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
