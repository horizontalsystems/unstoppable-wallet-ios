import Foundation
import RxSwift
import RxRelay
import MarketKit

class WalletManager {
    private let accountManager: AccountManager
    private let storage: WalletStorage
    private let disposeBag = DisposeBag()

    private let activeWalletDataRelay = PublishRelay<WalletData>()

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet_manager", qos: .userInitiated)

    private var cachedActiveWalletData = WalletData(wallets: [], account: nil)

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

    private func _reloadWallets() {
        guard let activeAccount = accountManager.activeAccount else {
            cachedActiveWalletData = WalletData(wallets: [], account: nil)
            return
        }

        do {
            cachedActiveWalletData = WalletData(wallets: try storage.wallets(account: activeAccount), account: activeAccount)
        } catch {
            // todo
            cachedActiveWalletData = WalletData(wallets: [], account: activeAccount)
        }

        activeWalletDataRelay.accept(cachedActiveWalletData)
    }

    private func reloadWallets() {
        queue.async { [weak self] in self?._reloadWallets() }
    }

}

extension WalletManager {

    var activeWalletData: WalletData {
        queue.sync { cachedActiveWalletData }
    }

    var activeWallets: [Wallet] {
        activeWalletData.wallets
    }

    var activeWalletDataUpdatedObservable: Observable<WalletData> {
        activeWalletDataRelay.asObservable()
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

extension WalletManager {

    struct WalletData {
        let wallets: [Wallet]
        let account: Account?
    }

}
