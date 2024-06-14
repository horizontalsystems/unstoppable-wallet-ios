import Combine
import Foundation
import HsExtensions
import MarketKit

class CoinInvestorsViewModel: ObservableObject {
    private let coinUid: String
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    private var tasks = Set<AnyTask>()

    @Published private(set) var state: State = .loading

    init(coinUid: String) {
        self.coinUid = coinUid

        sync()
    }

    private func sync() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, coinUid] in
            do {
                let investments = try await marketKit.investments(coinUid: coinUid)

                await MainActor.run { [weak self] in
                    self?.state = .loaded(investments: investments)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.state = .failed
                }
            }
        }
        .store(in: &tasks)
    }
}

extension CoinInvestorsViewModel {
    var usdCurrency: Currency {
        let currencies = currencyManager.currencies
        return currencies.first { $0.code == "USD" } ?? currencies[0]
    }

    func onRetry() {
        sync()
    }
}

extension CoinInvestorsViewModel {
    enum State {
        case loading
        case loaded(investments: [CoinInvestment])
        case failed
    }
}
