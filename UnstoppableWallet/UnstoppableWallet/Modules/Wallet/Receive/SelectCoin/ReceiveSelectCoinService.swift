import Foundation
import HsExtensions
import MarketKit

class ReceiveSelectCoinService {
    private let provider: CoinProvider

    @PostPublished private(set) var coins = [FullCoin]()

    init(provider: CoinProvider) {
        self.provider = provider

        sync()
    }

    private func sync() {
        coins = provider.fetch()
    }

}

extension ReceiveSelectCoinService {

    func set(filter: String) {
        provider.filter = filter

        sync()
    }

    func fullCoin(uid: String) -> FullCoin? {
        coins.first { coin in
            coin.coin.uid == uid
        }
    }

}
