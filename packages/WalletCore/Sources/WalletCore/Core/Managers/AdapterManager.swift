import Combine
import Foundation
import MarketKit

public final class AdapterManager {
    private var cancellables = Set<AnyCancellable>()

    private let adapterFactory: IAdapterFactory
    private let walletManager: WalletManager

    private let adapterDataReadySubject = PassthroughSubject<AdapterData, Never>()

    private let queue = DispatchQueue(label: "WalletCore.adapter_manager", qos: .userInitiated)
    private var _adapterData = AdapterData(adapterMap: [:], account: nil)

    public init(adapterFactory: IAdapterFactory, walletManager: WalletManager) {
        self.adapterFactory = adapterFactory
        self.walletManager = walletManager

        walletManager.activeWalletDataUpdatedPublisher
            .sink { [weak self] walletData in
                self?.initAdapters(wallets: walletData.wallets, account: walletData.account)
            }
            .store(in: &cancellables)
    }

    private func initAdapters(wallets: [Wallet], account: Account?) {
        let result = queue.sync {
            _rebuildLocked(wallets: wallets, account: account, recreating: [])
        }
        publish(result)
    }

    /// Rebuilds `_adapterData` in a single critical section and returns the side-effects
    /// (subject payload + adapters to stop) for the caller to perform outside the lock.
    /// - Parameters:
    ///   - wallets: the authoritative active wallet set.
    ///   - account: the account associated with the wallet set.
    ///   - recreating: subset of wallets whose adapters must be forcibly stopped and recreated even if already present.
    ///
    /// Must be called while holding `queue` (i.e. from inside a `queue.sync`/`queue.async` block). Does not lock again.
    /// The caller is responsible for invoking `publish(_:)` on the returned value after releasing the lock.
    private func _rebuildLocked(wallets: [Wallet], account: Account?, recreating: Set<Wallet>) -> RebuildResult {
        var newAdapterMap = _adapterData.adapterMap
        var stoppedAdapters = [IAdapter]()

        // 1. Stop and drop adapters that are being forcibly recreated.
        for wallet in recreating {
            if let adapter = newAdapterMap.removeValue(forKey: wallet) {
                stoppedAdapters.append(adapter)
            }
        }

        // 2. Create adapters for active wallets that don't currently have one.
        for wallet in wallets {
            guard newAdapterMap[wallet] == nil else {
                continue
            }
            if let adapter = adapterFactory.adapter(wallet: wallet) {
                newAdapterMap[wallet] = adapter
                adapter.start()
            }
        }

        // 3. Stop and drop adapters for wallets no longer active.
        for wallet in Array(newAdapterMap.keys) {
            guard !wallets.contains(wallet), let adapter = newAdapterMap.removeValue(forKey: wallet) else {
                continue
            }
            stoppedAdapters.append(adapter)
        }

        let newAdapterData = AdapterData(adapterMap: newAdapterMap, account: account)
        _adapterData = newAdapterData

        return RebuildResult(newData: newAdapterData, stoppedAdapters: stoppedAdapters)
    }

    /// Performs the side-effects of a rebuild outside the critical section: emits the new data
    /// on the subject and stops every adapter that was removed or replaced.
    private func publish(_ result: RebuildResult) {
        adapterDataReadySubject.send(result.newData)
        for adapter in result.stoppedAdapters {
            adapter.stop()
        }
    }
}

public extension AdapterManager {
    var adapterData: AdapterData {
        queue.sync { _adapterData }
    }

    var adapterDataReadyPublisher: AnyPublisher<AdapterData, Never> {
        adapterDataReadySubject.eraseToAnyPublisher()
    }

    func adapter(for wallet: Wallet) -> IAdapter? {
        queue.sync { _adapterData.adapterMap[wallet] }
    }

    func adapter(for token: Token) -> IAdapter? {
        queue.sync {
            guard let wallet = walletManager.activeWallets.first(where: { $0.token == token }) else {
                return nil
            }

            return _adapterData.adapterMap[wallet]
        }
    }

    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter? {
        queue.sync { _adapterData.adapterMap[wallet] as? IBalanceAdapter }
    }

    func depositAdapter(for wallet: Wallet) -> IDepositAdapter? {
        queue.sync { _adapterData.adapterMap[wallet] as? IDepositAdapter }
    }

    func reloadAdapters(forBlockchainType blockchainType: BlockchainType) {
        let result: RebuildResult? = queue.sync {
            let activeWalletData = walletManager.activeWalletData
            let recreating = Set(_adapterData.adapterMap.keys.filter { $0.token.blockchainType == blockchainType })
            guard !recreating.isEmpty else { return nil }
            return _rebuildLocked(wallets: activeWalletData.wallets, account: activeWalletData.account, recreating: recreating)
        }
        if let result {
            publish(result)
        }
    }

    func reloadRestoredAdapters(forBlockchainType blockchainType: BlockchainType) {
        let result: RebuildResult? = queue.sync {
            let activeWalletData = walletManager.activeWalletData
            let recreating = Set(_adapterData.adapterMap.keys.filter {
                $0.token.blockchainType == blockchainType && $0.account.origin == .restored
            })
            guard !recreating.isEmpty else { return nil }
            return _rebuildLocked(wallets: activeWalletData.wallets, account: activeWalletData.account, recreating: recreating)
        }
        if let result {
            publish(result)
        }
    }

    func refreshAdapters() {
        let adapters = queue.sync { _adapterData.adapterMap.values }
        for adapter in adapters {
            adapter.refresh()
        }
    }

    func refreshAdapter(wallet: Wallet) {
        let adapter = queue.sync { _adapterData.adapterMap[wallet] }
        adapter?.refresh()
    }
}

public extension AdapterManager {
    struct AdapterData {
        public var adapterMap: [Wallet: IAdapter]
        public let account: Account?

        public init(adapterMap: [Wallet: IAdapter], account: Account?) {
            self.adapterMap = adapterMap
            self.account = account
        }
    }
}

private extension AdapterManager {
    struct RebuildResult {
        let newData: AdapterData
        let stoppedAdapters: [IAdapter]
    }
}
