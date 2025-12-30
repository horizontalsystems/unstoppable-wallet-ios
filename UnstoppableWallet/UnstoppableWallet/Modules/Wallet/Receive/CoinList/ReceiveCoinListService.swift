import Foundation
import HsExtensions
import MarketKit

class ReceiveCoinListService {
    private let provider: CoinProvider
    private let accountType: AccountType
    private let settingsService = RestoreSettingsService(manager: Core.shared.restoreSettingsManager)

    private var filter: String = "" {
        didSet {
            sync()
        }
    }

    @PostPublished private(set) var coins = [FullCoin]()

    init(provider: CoinProvider, accountType: AccountType) {
        self.provider = provider
        self.accountType = accountType

        sync()
    }

    private func sync() {
        let coins = provider.fetch(filter: filter)

        if filter.isEmpty, !coins.isEmpty {
            let sorted = CoinSorter.sort(coins, accountType: accountType, options: [.fiatValue, .blockchain, .name])
            update(coins: sorted)
        } else {
            update(coins: coins)
        }
    }

    private func update(coins: [FullCoin]) {
        DispatchQueue.main.async {
            self.coins = coins
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
