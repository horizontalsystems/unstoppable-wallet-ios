import Foundation
import HsExtensions
import MarketKit

class ReceiveSelectCoinService {
    private let provider: CoinProvider

    private var filter: String = "" {
        didSet {
            sync()
        }
    }

    @PostPublished private(set) var coins = [FullCoin]()

    init(provider: CoinProvider) {
        self.provider = provider

        sync()
    }

    private func sync() {
        let coins = provider.fetch(filter: filter)

        if filter.isEmpty {
            self.coins = coins
            return
        }

        self.coins = coins.sorted { lhsFullCoin, rhsFullCoin in
            let filter = filter.lowercased()

            let lhsExactCode = lhsFullCoin.coin.code.lowercased() == filter
            let rhsExactCode = rhsFullCoin.coin.code.lowercased() == filter

            if lhsExactCode != rhsExactCode {
                return lhsExactCode
            }

            let lhsStartsWithCode = lhsFullCoin.coin.code.lowercased().starts(with: filter)
            let rhsStartsWithCode = rhsFullCoin.coin.code.lowercased().starts(with: filter)

            if lhsStartsWithCode != rhsStartsWithCode {
                return lhsStartsWithCode
            }

            let lhsStartsWithName = lhsFullCoin.coin.name.lowercased().starts(with: filter)
            let rhsStartsWithName = rhsFullCoin.coin.name.lowercased().starts(with: filter)

            if lhsStartsWithName != rhsStartsWithName {
                return lhsStartsWithName
            }

            return lhsFullCoin.coin.name.lowercased() < rhsFullCoin.coin.name.lowercased()
        }
    }
}

extension ReceiveSelectCoinService {
    func set(filter: String) {
        self.filter = filter
    }

    func fullCoin(uid: String) -> FullCoin? {
        coins.first { coin in
            coin.coin.uid == uid
        }
    }
}
