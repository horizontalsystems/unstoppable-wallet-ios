import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import HsExtensions

class CoinInvestorsService {
    private let coinUid: String
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: DataStatus<[CoinInvestment]> = .loading

    init(coinUid: String, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.coinUid = coinUid
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        sync()
    }

    private func sync() {
        tasks = Set()

        state = .loading

        Task { [weak self, marketKit, coinUid] in
            do {
                let investments = try await marketKit.investments(coinUid: coinUid)
                self?.state = .completed(investments)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

}

extension CoinInvestorsService {

    var usdCurrency: Currency {
        let currencies = currencyKit.currencies
        return currencies.first { $0.code == "USD" } ?? currencies[0]
    }

    func refresh() {
        sync()
    }

}
