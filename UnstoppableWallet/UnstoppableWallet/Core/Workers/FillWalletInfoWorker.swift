import RxSwift
import MarketKit
import StorageKit

class FillWalletInfoWorker {
    private let localStorageKey = "fill-wallet-info-worker-run"

    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private let storage: EnabledWalletStorage
    private let localStorage: StorageKit.ILocalStorage

    init(marketKit: MarketKit.Kit, walletManager: WalletManager, storage: EnabledWalletStorage, localStorage: StorageKit.ILocalStorage) {
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.storage = storage
        self.localStorage = localStorage
    }

}

extension FillWalletInfoWorker {

    func run() throws {
        let alreadyRun: Bool = localStorage.value(for: localStorageKey) ?? false

        guard !alreadyRun else {
            return
        }

        localStorage.set(value: true, for: localStorageKey)

        let enabledWallets = try storage.enabledWallets()
        let nonFilledWallets = enabledWallets.filter { $0.coinName == nil || $0.coinCode == nil || $0.coinDecimals == nil }

        guard !nonFilledWallets.isEmpty else {
            return
        }

        let coinTypeIds = nonFilledWallets.map { $0.coinId }
        let platformCoins = try marketKit.platformCoins(coinTypeIds: coinTypeIds)

        var updatedEnabledWallets = [EnabledWallet]()

        for platformCoin in platformCoins {
            guard let enabledWallet = enabledWallets.first(where: { $0.coinId == platformCoin.coinType.id }) else {
                continue
            }

            let updatedEnabledWallet = EnabledWallet(
                    coinId: enabledWallet.coinId,
                    coinSettingsId: enabledWallet.coinSettingsId,
                    accountId: enabledWallet.accountId,
                    coinName: platformCoin.name,
                    coinCode: platformCoin.code,
                    coinDecimals: platformCoin.decimals
            )

            updatedEnabledWallets.append(updatedEnabledWallet)
        }

        try storage.handle(newEnabledWallets: updatedEnabledWallets, deletedEnabledWallets: [])
        walletManager.preloadWallets()
    }

}
