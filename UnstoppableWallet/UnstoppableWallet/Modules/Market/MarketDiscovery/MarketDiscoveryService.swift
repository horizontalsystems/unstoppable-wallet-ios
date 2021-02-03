import CurrencyKit
import XRatesKit
import RxSwift
import RxRelay

class MarketDiscoveryService {
    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager
    private let categoriesProvider: MarketCategoriesProvider
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private(set) var items = [MarketModule.Item]()

    private let currentCategoryRelay = PublishRelay<MarketDiscoveryFilter?>()
    var currentCategory: MarketDiscoveryFilter? {
        didSet {
            currentCategoryRelay.accept(currentCategory)
            items = []
            fetch()
        }
    }

    init(currencyKit: ICurrencyKit, rateManager: IRateManager, categoriesProvider: MarketCategoriesProvider) {
        self.currencyKit = currencyKit
        self.rateManager = rateManager
        self.categoriesProvider = categoriesProvider

        fetch()
    }

    private func fetch() {
        disposeBag = DisposeBag()

        state = .loading

        let single: Single<[CoinMarket]>

        if let category = currentCategory {
//            let coinCodes = categoriesProvider.coinCodes(for: category == .rated ? nil : category.rawValue)
            let coinCodes = categoriesProvider.coinCodes(for: category.rawValue)
            single = rateManager.coinsMarketSingle(currencyCode: currencyKit.baseCurrency.code, coinCodes: coinCodes)
        } else {
            single = rateManager.topMarketsSingle(currencyCode: currencyKit.baseCurrency.code, itemCount: 250)
        }

        single
                .subscribe(onSuccess: { [weak self] coinMarkets in
                    self?.onFetchSuccess(coinMarkets: coinMarkets)
                }, onError: { [weak self] error in
                    self?.onFetchFailed(error: error)
                })
                .disposed(by: disposeBag)
    }

    private func onFetchSuccess(coinMarkets: [CoinMarket]) {
        items = coinMarkets.enumerated().compactMap { index, coinMarket in
            let score: MarketModule.Score?
            switch currentCategory {
//            case .rated:
//                guard let rate = categoriesProvider.rate(for: coinMarket.coin.code), !rate.isEmpty else {
//                    return nil
//                }
//
//                score = .rating(rate)
            case .none:
                score = .rank(index + 1)
            default:
                score = nil
            }
            return MarketModule.Item(coinMarket: coinMarket, score: score)
        }

        state = .loaded
    }

    private func onFetchFailed(error: Error) {
        state = .failed(error: error)
    }

}

extension MarketDiscoveryService {

    var currency: Currency {
        //todo: refactor to use current currency and handle changing
        currencyKit.currencies.first { $0.code == "USD" } ?? currencyKit.currencies[0]
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var currentCategoryObservable: Observable<MarketDiscoveryFilter?> {
        currentCategoryRelay.asObservable()
    }

    func refresh() {
        fetch()
    }

}

extension MarketDiscoveryService {

    enum State {
        case loaded
        case loading
        case failed(error: Error)
    }

}
