import Combine
import Foundation
import MarketKit
import RxRelay
import RxSwift

class WalletManager {
    private let accountManager: AccountManager
    private let storage: WalletStorage
    private var cancellables = Set<AnyCancellable>()

    private let activeWalletDataRelay = PublishRelay<WalletData>()

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet_manager", qos: .userInitiated)

    private var cachedActiveWalletData = WalletData(wallets: [], account: nil)

    init(accountManager: AccountManager, storage: WalletStorage) {
        self.accountManager = accountManager
        self.storage = storage

        accountManager.activeAccountPublisher
            .sink { [weak self] _ in self?.reloadWallets() }
            .store(in: &cancellables)

        accountManager.accountDeletedPublisher
            .sink { [weak self] in self?.handleDelete(account: $0) }
            .store(in: &cancellables)
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
        if let activeAccount = accountManager.activeAccount {
            do {
                cachedActiveWalletData = try WalletData(wallets: storage.wallets(account: activeAccount), account: activeAccount)
            } catch {
                // todo
                cachedActiveWalletData = WalletData(wallets: [], account: activeAccount)
            }
        } else {
            cachedActiveWalletData = WalletData(wallets: [], account: nil)
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
