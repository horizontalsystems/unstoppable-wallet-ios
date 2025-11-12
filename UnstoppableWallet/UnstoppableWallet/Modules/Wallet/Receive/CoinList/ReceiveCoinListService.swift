import Foundation
import HsExtensions
import MarketKit

class ReceiveCoinListService {
    private let provider: CoinProvider
    private let settingsService = RestoreSettingsService(manager: Core.shared.restoreSettingsManager)

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

        if coins.isEmpty {
            self.coins = []
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

    func onRestoreWithBirthdayHeight(account: Account, token: Token, height: Int?) {
        // create token with birthdayHeight
        let tokenWithSettings = settingsService.enter(birthdayHeight: height, token: token)
        settingsService.save(settings: tokenWithSettings.settings, account: account, blockchainType: token.blockchainType)

        // create wallet for token
        ReceiveModule.createWallet(account: account, token: token)
    }
}

extension ReceiveCoinListService {
    func set(filter: String) {
        self.filter = filter
    }

    func fullCoin(uid: String) -> FullCoin? {
        coins.first { coin in
            coin.coin.uid == uid
        }
    }
}
