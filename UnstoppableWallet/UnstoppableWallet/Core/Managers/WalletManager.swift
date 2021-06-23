import RxSwift
import RxRelay
import CoinKit

class WalletManager {
    private let accountManager: IAccountManager
    private let adapterProviderFactory: AdapterFactory
    private let storage: IWalletStorage
    private let disposeBag = DisposeBag()

    private let activeWalletsRelay = PublishRelay<[Wallet]>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet_manager", qos: .userInitiated)

    private var cachedActiveWallets = [Wallet]()

    init(accountManager: IAccountManager, adapterProviderFactory: AdapterFactory, storage: IWalletStorage) {
        self.accountManager = accountManager
        self.adapterProviderFactory = adapterProviderFactory
        self.storage = storage

        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] _ in self?.reloadWallets() }
        subscribe(disposeBag, accountManager.accountDeletedObservable) { [weak self] in self?.handleDelete(account: $0) }
    }

    private func handleDelete(account: Account) {
        let accountWallets = storage.wallets(account: account)
        storage.handle(newWallets: [], deletedWallets: accountWallets)
    }

    private var activeAccountWallets: [Wallet] {
        guard let activeAccount = accountManager.activeAccount else {
            return []
        }

        return storage.wallets(account: activeAccount)
    }

    private func _reloadWallets() {
        cachedActiveWallets = activeAccountWallets
        activeWalletsRelay.accept(cachedActiveWallets)
    }

    private func reloadWallets() {
        queue.async { [weak self] in self?._reloadWallets() }
    }

}

extension WalletManager {

    var activeWallets: [Wallet] {
        queue.sync { cachedActiveWallets }
    }

    var activeWalletsUpdatedObservable: Observable<[Wallet]> {
        activeWalletsRelay.asObservable()
    }

    func preloadWallets() {
        reloadWallets()
    }

    func wallets(account: Account) -> [Wallet] {
        storage.wallets(account: account)
    }

    func handle(newWallets: [Wallet], deletedWallets: [Wallet]) {
        storage.handle(newWallets: newWallets, deletedWallets: deletedWallets)
        reloadWallets()
    }

    func save(wallets: [Wallet]) {
        handle(newWallets: wallets, deletedWallets: [])
    }

    func delete(wallets: [Wallet]) {
        handle(newWallets: [], deletedWallets: wallets)
    }

    func clearWallets() {
        storage.clearWallets()
    }

}
