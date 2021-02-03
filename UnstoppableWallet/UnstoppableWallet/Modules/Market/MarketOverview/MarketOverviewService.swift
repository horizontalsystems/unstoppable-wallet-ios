import CurrencyKit
import XRatesKit
import Foundation
import RxSwift
import RxRelay

class MarketOverviewService {
    private var disposeBag = DisposeBag()

    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private(set) var items = [MarketModule.Item]()

    init(currencyKit: ICurrencyKit, rateManager: IRateManager) {
        self.currencyKit = currencyKit
        self.rateManager = rateManager

        fetch()
    }

    private func fetch() {
        disposeBag = DisposeBag()

        state = .loading

        rateManager.topMarketsSingle(currencyCode: currency.code, itemCount: 250)
                .subscribe(onSuccess: { [weak self] in
                    self?.onFetchSuccess(items: $0)
                }, onError: { [weak self] error in
                    self?.onFetchFailed(error: error)
                })
                .disposed(by: disposeBag)
    }

    private func onFetchSuccess(items: [CoinMarket]) {
        self.items = items.enumerated().map { (index, coinMarket) in
            MarketModule.Item(coinMarket: coinMarket, score: .rank(index + 1))
        }

        state = .loaded
    }

    private func onFetchFailed(error: Error) {
        state = .failed(error: error)
    }

}

extension MarketOverviewService {

    var currency: Currency {
        //todo: refactor to use current currency and handle changing
        currencyKit.currencies.first { $0.code == "USD" } ?? currencyKit.currencies[0]
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func refresh() {
        fetch()
    }

}

extension MarketOverviewService {

    enum State {
        case loaded
        case loading
        case failed(error: Error)
    }

}
