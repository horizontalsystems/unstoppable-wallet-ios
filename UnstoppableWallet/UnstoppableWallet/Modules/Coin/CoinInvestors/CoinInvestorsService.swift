import HsExtensions
import MarketKit
import RxRelay
import RxSwift

class CoinInvestorsService {
    private let coinUid: String
    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: DataStatus<[CoinInvestment]> = .loading

    init(coinUid: String, marketKit: MarketKit.Kit, currencyManager: CurrencyManager) {
        self.coinUid = coinUid
        self.marketKit = marketKit
        self.currencyManager = currencyManager

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
        let currencies = currencyManager.currencies
        return currencies.first { $0.code == "USD" } ?? currencies[0]
    }

    func refresh() {
        sync()
    }
}
