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

    func prepareEnable(fullCoin: FullCoin, account: Account) {
        let eligibleTokens = fullCoin.tokens.filter { account.type.supports(token: $0) }

        guard let token = eligibleTokens.first else {
            return
        }

        let blockchainType = token.blockchainType

        switch blockchainType {
        case .zcash, .monero, .zano:
            let settings = settingsService.settings(accountId: account.id, blockchainType: blockchainType)

            if settings[.birthdayHeight] == nil, let birthdayHeight = RestoreSettingType.birthdayHeight.createdAccountValue(blockchainType: blockchainType) {
                settingsService.set(birthdayHeight: birthdayHeight, account: account, blokcchainType: blockchainType)
            }
        default: ()
        }
    }
}
