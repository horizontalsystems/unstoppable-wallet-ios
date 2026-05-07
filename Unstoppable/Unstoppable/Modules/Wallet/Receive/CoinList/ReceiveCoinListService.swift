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
            let (balances, coinPrices) = collectActiveBalancesAndPrices(for: coins)
            let context = FullCoinSortContext(
                coins: coins,
                balances: balances,
                coinPrices: coinPrices,
                accountType: accountType
            )
            let sorted = coins.sorted(
                by: SortCriterion.receiveCoin,
                context: context
            )
            update(coins: sorted)
        } else {
            // Filter is active: keep marketKit's relevance order, but float native variants of
            // same-code coins to the top (.codeNativeFirst is the only criterion that fires here;
            // all other criteria are orderedSame so the relative order is preserved by stable sort).
            let sorted = coins.sorted(by: SortCriterion.receiveCoinFiltered, context: FullCoinSortContext())
            update(coins: sorted)
        }
    }

    private func collectActiveBalancesAndPrices(for coins: [FullCoin]) -> (balances: [Token: Decimal], coinPrices: [String: Decimal]) {
        let eligibleTokens = coins.flatMap { $0.tokens.filter { accountType.supports(token: $0) } }
        let coinUids = Array(Set(eligibleTokens.map(\.coin.uid)))

        let currency = Core.shared.currencyManager.baseCurrency
        let coinPriceMap = Core.shared.marketKit.coinPriceMap(coinUids: coinUids, currencyCode: currency.code)
        let coinPrices: [String: Decimal] = coinPriceMap.compactMapValues { $0.expired ? nil : $0.value }

        let activeWallets = Core.shared.walletManager.activeWallets
        var balances: [Token: Decimal] = [:]
        for wallet in activeWallets {
            if let adapter = Core.shared.adapterManager.adapter(for: wallet) as? IBalanceAdapter {
                balances[wallet.token] = adapter.balanceData.available
            }
        }

        return (balances, coinPrices)
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
