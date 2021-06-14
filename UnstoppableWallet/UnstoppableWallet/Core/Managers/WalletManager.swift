import RxSwift
import RxRelay
import CoinKit

class WalletManager {
    private let accountManager: IAccountManager
    private let adapterProviderFactory: AdapterProviderFactory
    private let storage: IWalletStorage
    private let disposeBag = DisposeBag()

    private let activeWalletsRelay = PublishRelay<[ActiveWallet]>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet_manager", qos: .userInitiated)

    private var cachedActiveWallets = [ActiveWallet]()

    init(accountManager: IAccountManager, adapterProviderFactory: AdapterProviderFactory, storage: IWalletStorage) {
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

    private func activeWallet(wallet: Wallet) -> ActiveWallet {
        let adapterProvider = adapterProviderFactory.adapterProvider(wallet: wallet)
        let activeWallet = ActiveWallet(wallet: wallet, adapterProvider: adapterProvider)
        activeWallet.initAdapter()
        return activeWallet
    }

    private func _reloadWallets() {
        let newActiveWallets = activeAccountWallets.map { wallet in
            cachedActiveWallets.first { $0.wallet == wallet } ?? activeWallet(wallet: wallet)
        }

        cachedActiveWallets = newActiveWallets
        activeWalletsRelay.accept(cachedActiveWallets)
    }

    private func reloadWallets() {
        queue.async { [weak self] in self?._reloadWallets() }
    }

}

extension WalletManager: IWalletManager {

    var activeWallets: [ActiveWallet] {
        queue.sync { cachedActiveWallets }
    }

    var activeWalletsUpdatedObservable: Observable<[ActiveWallet]> {
        activeWalletsRelay.asObservable()
    }

    func activeWallet(wallet: Wallet) -> ActiveWallet? {
        queue.sync { cachedActiveWallets.first { $0.wallet == wallet } }
    }

    func activeWallet(coin: Coin) -> ActiveWallet? {
        queue.sync { cachedActiveWallets.first { $0.wallet.coin == coin } }
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

    func refreshWallets() {
        queue.sync {
            var ethereumKitUpdated = false
            var binanceSmartChainKitUpdated = false
            var binanceKitUpdated = false

            for activeWallet in cachedActiveWallets {
                switch activeWallet.wallet.coin.type {
                case .ethereum, .erc20:
                    if !ethereumKitUpdated {
                        activeWallet.refresh()
                        ethereumKitUpdated = true
                    }
                case .binanceSmartChain, .bep20:
                    if !binanceSmartChainKitUpdated {
                        activeWallet.refresh()
                        binanceSmartChainKitUpdated = true
                    }
                case .bep2:
                    if !binanceKitUpdated {
                        activeWallet.refresh()
                        binanceKitUpdated = true
                    }
                default:
                    activeWallet.refresh()
                }
            }
        }
    }

}
