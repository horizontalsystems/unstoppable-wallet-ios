import Foundation
import MarketKit
import CurrencyKit
import HsExtensions

class CoinMarketsService: IMarketSingleSortHeaderService {
    private let coin: Coin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: State = .loading

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
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, coin] in
            do {
                let tickers = try await marketKit.marketTickers(coinUid: coin.uid)
                self?.sync(tickers: tickers)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
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
