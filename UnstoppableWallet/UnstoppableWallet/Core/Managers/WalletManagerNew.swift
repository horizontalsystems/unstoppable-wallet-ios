import RxSwift
import RxRelay
import MarketKit

class WalletManagerNew {
    private let accountManager: IAccountManager
    private let storage: WalletStorageNew
    private let disposeBag = DisposeBag()

    private let activeWalletsRelay = PublishRelay<[WalletNew]>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet_manager", qos: .userInitiated)

    private var cachedActiveWallets = [WalletNew]()

    init(accountManager: IAccountManager, storage: WalletStorageNew) {
        self.accountManager = accountManager
        self.storage = storage

        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] _ in self?.reloadWallets() }
        subscribe(disposeBag, accountManager.accountDeletedObservable) { [weak self] in self?.handleDelete(account: $0) }
    }

    private func handleDelete(account: Account) {
        do {
            let accountWallets = try storage.wallets(account: account)
            storage.handle(newWallets: [], deletedWallets: accountWallets)
        } catch {
            // todo
        }
    }

    private var activeAccountWallets: [WalletNew] {
        guard let activeAccount = accountManager.activeAccount else {
            return []
        }

        do {
            return try storage.wallets(account: activeAccount)
        } catch {
            // todo
            return []
        }
    }

    private func _reloadWallets() {
        cachedActiveWallets = activeAccountWallets
        activeWalletsRelay.accept(cachedActiveWallets)
    }

    private func reloadWallets() {
        queue.async { [weak self] in self?._reloadWallets() }
    }

}

extension WalletManagerNew {

    var activeWallets: [WalletNew] {
        queue.sync { cachedActiveWallets }
    }

    var activeWalletsUpdatedObservable: Observable<[WalletNew]> {
        activeWalletsRelay.asObservable()
    }

    func preloadWallets() {
        reloadWallets()
    }

    func wallets(account: Account) -> [WalletNew] {
        do {
            return try storage.wallets(account: account)
        } catch {
            // todo
            return []
        }
    }

    func handle(newWallets: [WalletNew], deletedWallets: [WalletNew]) {
        storage.handle(newWallets: newWallets, deletedWallets: deletedWallets)
        reloadWallets()
    }

    func save(wallets: [WalletNew]) {
        handle(newWallets: wallets, deletedWallets: [])
    }

    func delete(wallets: [WalletNew]) {
        handle(newWallets: [], deletedWallets: wallets)
    }

    func clearWallets() {
        storage.clearWallets()
    }

}
