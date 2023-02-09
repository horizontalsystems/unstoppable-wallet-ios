import Foundation
import RxSwift
import RxRelay
import MarketKit

class WalletManager {
    private let accountManager: AccountManager
    private let storage: WalletStorage
    private let disposeBag = DisposeBag()

    private let activeWalletsRelay = PublishRelay<[Wallet]>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet_manager", qos: .userInitiated)

    private var cachedActiveWallets = [Wallet]()

    init(accountManager: AccountManager, storage: WalletStorage) {
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

    private var activeAccountWallets: [Wallet] {
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
        do {
            return try storage.wallets(account: account)
        } catch {
            // todo
            return []
        }
    }

    func handle(newWallets: [Wallet], deletedWallets: [Wallet]) {
        storage.handle(newWallets: newWallets, deletedWallets: deletedWallets)
        reloadWallets()
    }

    func save(wallets: [Wallet]) {
        handle(newWallets: wallets, deletedWallets: [])
    }

    func save(enabledWallets: [EnabledWallet]) {
        storage.handle(newEnabledWallets: enabledWallets)
        reloadWallets()
    }

    func delete(wallets: [Wallet]) {
        handle(newWallets: [], deletedWallets: wallets)
    }

    func clearWallets() {
        storage.clearWallets()
    }

}
