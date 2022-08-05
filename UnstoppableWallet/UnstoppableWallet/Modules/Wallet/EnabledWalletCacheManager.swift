import RxSwift

class EnabledWalletCacheManager {
    private let storage: EnabledWalletCacheStorage
    private let disposeBag = DisposeBag()

    init(storage: EnabledWalletCacheStorage, accountManager: AccountManager) {
        self.storage = storage

        subscribe(disposeBag, accountManager.accountDeletedObservable) { [weak self] in self?.handleDelete(account: $0) }
    }

    private func handleDelete(account: Account) {
        storage.deleteEnabledWalletCaches(accountId: account.id)
    }

}

extension EnabledWalletCacheManager {

    func cacheContainer(accountId: String) -> CacheContainer {
        CacheContainer(caches: storage.enabledWalletCaches(accountId: accountId))
    }

    func set(balanceDataMap: [Wallet: BalanceData]) {
        let caches = balanceDataMap.map { wallet, balanceData in
            EnabledWalletCache(wallet: wallet, balanceData: balanceData)
        }
        storage.save(enabledWalletCaches: caches)
    }

    func set(balanceData: BalanceData, wallet: Wallet) {
        let cache = EnabledWalletCache(wallet: wallet, balanceData: balanceData)
        storage.save(enabledWalletCaches: [cache])
    }

}

extension EnabledWalletCacheManager {

    struct CacheContainer {
        private let caches: [EnabledWalletCache]

        init(caches: [EnabledWalletCache]) {
            self.caches = caches
        }

        func balanceData(wallet: Wallet) -> BalanceData? {
            caches.first { $0.tokenQueryId == wallet.token.tokenQuery.id && $0.coinSettingsId == wallet.coinSettings.id }?.balanceData
        }
    }

}
