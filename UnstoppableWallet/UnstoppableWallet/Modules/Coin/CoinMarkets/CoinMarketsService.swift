import Foundation
import MarketKit
import RxSwift
import RxRelay
import CurrencyKit

class CoinMarketsService: IMarketSingleSortHeaderService {
    private let coin: Coin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    var sortDirectionAscending: Bool = false {
        didSet {
            syncIfPossible()
        }
    }

    init(coin: Coin, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.coin = coin
        self.marketKit = marketKit
        self.currencyKit = currencyKit
    }

    private func syncTickers() {
        disposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        marketKit.marketTickersSingle(coinUid: coin.uid)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] tickers in
                    self?.sync(tickers: tickers)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: disposeBag)
    }

    private func sync(tickers: [MarketTicker], reorder: Bool = false) {
        state = .loaded(tickers: sorted(tickers: tickers), reorder: reorder)
    }

    private func syncIfPossible() {
        guard case .loaded(let tickers, _) = state else {
            return
        }

        sync(tickers: tickers, reorder: true)
    }

    private func sorted(tickers: [MarketTicker]) -> [MarketTicker] {
        sortDirectionAscending ? tickers.sorted { $0.volume < $1.volume } : tickers.sorted { $0.volume > $1.volume }
    }

}

extension CoinMarketsService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var price: Decimal? {
        marketKit.coinPrice(coinUid: coin.uid, currencyCode: currency.code)?.value
    }

    var coinCode: String {
        coin.code
    }

    func sync() {
        syncTickers()
    }

}

extension CoinMarketsService {

    enum State {
        case loading
        case loaded(tickers: [MarketTicker], reorder: Bool)
        case failed(error: Error)
    }

}
