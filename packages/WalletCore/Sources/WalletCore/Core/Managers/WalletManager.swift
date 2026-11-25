import Combine
import Foundation
import MarketKit
import RxRelay
import RxSwift

public class WalletManager {
    private let accountManager: AccountManager
    private let storage: WalletStorage
    private var cancellables = Set<AnyCancellable>()

    private let activeWalletDataRelay = PublishRelay<WalletData>()
    private let activeWalletDataSubject = PassthroughSubject<WalletData, Never>()

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet_manager", qos: .userInitiated)

    private var cachedActiveWalletData = WalletData(wallets: [], account: nil)

    /// The accounts whose wallets are active along with the active account; an app that shows several accounts
    /// as one wallet sets it and calls `reloadWallets()` when the set changes.
    public var activeAccounts: (Account) -> [Account]

    public init(accountManager: AccountManager, storage: WalletStorage, activeAccounts: @escaping (Account) -> [Account] = { [$0] }) {
        self.accountManager = accountManager
        self.storage = storage
        self.activeAccounts = activeAccounts

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
                cachedActiveWalletData = try WalletData(wallets: activeAccounts(activeAccount).flatMap { try storage.wallets(account: $0) }, account: activeAccount)
            } catch {
                // todo
                cachedActiveWalletData = WalletData(wallets: [], account: activeAccount)
            }
        } else {
            cachedActiveWalletData = WalletData(wallets: [], account: nil)
        }

        activeWalletDataRelay.accept(cachedActiveWalletData)
        activeWalletDataSubject.send(cachedActiveWalletData)
    }

    public func reloadWallets() {
        queue.async { [weak self] in self?._reloadWallets() }
    }
}

extension WalletManager {
    public var activeWalletData: WalletData {
        queue.sync { cachedActiveWalletData }
    }

    public var activeWallets: [Wallet] {
        activeWalletData.wallets
    }

    var activeWalletDataUpdatedObservable: Observable<WalletData> {
        activeWalletDataRelay.asObservable()
    }

    var activeWalletDataUpdatedPublisher: AnyPublisher<WalletData, Never> {
        activeWalletDataSubject.eraseToAnyPublisher()
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

    public func save(wallets: [Wallet]) {
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

public extension WalletManager {
    struct WalletData {
        public let wallets: [Wallet]
        public let account: Account?
    }
}
