import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketOverviewViewModelNew {
    private let service: MarketOverviewServiceNew
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)

    init(service: MarketOverviewServiceNew) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.topMarketState)
    }

    private func sync(state: MarketOverviewServiceNew.State) {
        switch state {
        case .loading:
            stateRelay.accept(.loading)
        case .loaded:
            stateRelay.accept(.loaded(viewItems: viewItems))
        case .failed:
            stateRelay.accept(.error(description: "market.sync_error".localized))
        }
    }

    private var viewItems: [MarketModule.ViewItem] {
        service.items.map {
            MarketModule.ViewItem(item: $0, marketField: .price, currency: service.currency)
        }
    }

}

extension MarketOverviewViewModelNew {

    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

    var topMarketLimit: Int {
        service.topMarket
    }

    func set(topMarketLimit: Int) {
        service.set(topMarketLimit: topMarketLimit)
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewViewModelNew {

    enum State {
        case loading
        case loaded(viewItems: [MarketModule.ViewItem])
        case error(description: String)
    }

}
