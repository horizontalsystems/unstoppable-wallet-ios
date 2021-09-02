import RxSwift
import RxRelay
import CoinKit

class AdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterFactory: AdapterFactory
    private let walletManager: WalletManager
    private let ethereumKitManager: EvmKitManager
    private let binanceSmartChainKitManager: EvmKitManager
    private let initialSyncSettingsManager: InitialSyncSettingsManager

    private let adaptersReadyRelay = PublishRelay<[Wallet: IAdapter]>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.adapter_manager", qos: .userInitiated)
    private var _adapterMap = [Wallet: IAdapter]()

    init(adapterFactory: AdapterFactory, walletManager: WalletManager, ethereumKitManager: EvmKitManager, binanceSmartChainKitManager: EvmKitManager, initialSyncSettingsManager: InitialSyncSettingsManager) {
        self.adapterFactory = adapterFactory
        self.walletManager = walletManager
        self.ethereumKitManager = ethereumKitManager
        self.binanceSmartChainKitManager = binanceSmartChainKitManager
        self.initialSyncSettingsManager = initialSyncSettingsManager

        walletManager.activeWalletsUpdatedObservable
                .observeOn(SerialDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] wallets in
                    self?.initAdapters(wallets: wallets)
                })
                .disposed(by: disposeBag)

        subscribe(disposeBag, ethereumKitManager.evmKitUpdatedObservable) { [weak self] in self?.handleUpdatedEthereumKit() }
        subscribe(disposeBag, binanceSmartChainKitManager.evmKitUpdatedObservable) { [weak self] in self?.handleUpdatedBinanceSmartChainKit() }
        subscribe(disposeBag, initialSyncSettingsManager.settingUpdatedObservable) { [weak self] in self?.handleUpdated(setting: $0) }
    }

    private func initAdapters(wallets: [Wallet]) {
        var newAdapterMap = queue.sync { _adapterMap }

        for wallet in wallets {
            guard newAdapterMap[wallet] == nil else {
                continue
            }

            if let adapter = adapterFactory.adapter(wallet: wallet) {
                newAdapterMap[wallet] = adapter
                adapter.start()
            }
        }

        var removedAdapters = [IAdapter]()

        for wallet in Array(newAdapterMap.keys) {
            guard !wallets.contains(wallet), let adapter = newAdapterMap.removeValue(forKey: wallet) else {
                continue
            }

            removedAdapters.append(adapter)
        }

        queue.async {
            self._adapterMap = newAdapterMap
            self.adaptersReadyRelay.accept(newAdapterMap)
        }

        removedAdapters.forEach { adapter in
            adapter.stop()
        }
    }

    private func handleUpdatedEthereumKit() {
        let wallets = queue.sync { _adapterMap.keys }

        refreshAdapters(wallets: wallets.filter {
            switch $0.coin.type {
            case .ethereum, .erc20: return true
            default: return false
            }
        })
    }

    private func handleUpdatedBinanceSmartChainKit() {
        let wallets = queue.sync { _adapterMap.keys }

        refreshAdapters(wallets: wallets.filter {
            switch $0.coin.type {
            case .binanceSmartChain, .bep20: return true
            default: return false
            }
        })
    }

    private func handleUpdated(setting: InitialSyncSetting) {
//        let wallets = queue.sync { _adapterMap.keys }
//
//        refreshAdapters(wallets: wallets.filter {
//            setting.coinType == $0.coin.type && $0.account.origin == .restored
//        })
    }

    private func refreshAdapters(wallets: [Wallet]) {
        guard !wallets.isEmpty else {
            return
        }

        queue.sync {
            wallets.forEach {
                _adapterMap[$0]?.stop()
                _adapterMap[$0] = nil
            }
        }

        initAdapters(wallets: walletManager.activeWallets)
    }

}

extension AdapterManager {

    var adapterMap: [Wallet: IAdapter] {
        queue.sync { _adapterMap }
    }

    var adaptersReadyObservable: Observable<[Wallet: IAdapter]> {
        adaptersReadyRelay.asObservable()
    }

    func adapter(for wallet: Wallet) -> IAdapter? {
        queue.sync { _adapterMap[wallet] }
    }

    func adapter(for coin: Coin) -> IAdapter? {
        queue.sync {
            guard let wallet = walletManager.activeWallets.first(where: { $0.coin == coin } ) else {
                return nil
            }

            return _adapterMap[wallet]
        }
    }

    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter? {
        queue.sync { _adapterMap[wallet] as? IBalanceAdapter }
    }

    func depositAdapter(for wallet: Wallet) -> IDepositAdapter? {
        queue.sync { _adapterMap[wallet] as? IDepositAdapter }
    }

    func refresh() {
        queue.async {
            var ethereumKitUpdated = false
            var binanceSmartChainKitUpdated = false
            var binanceKitUpdated = false

            for (wallet, adapter) in self._adapterMap {
                switch wallet.coin.type {
                case .ethereum, .erc20:
                    if !ethereumKitUpdated {
                        adapter.refresh()
                        ethereumKitUpdated = true
                    }
                case .binanceSmartChain, .bep20:
                    if !binanceSmartChainKitUpdated {
                        adapter.refresh()
                        binanceSmartChainKitUpdated = true
                    }
                case .bep2:
                    if !binanceKitUpdated {
                        adapter.refresh()
                        binanceKitUpdated = true
                    }
                default:
                    adapter.refresh()
                }
            }
        }
    }

    func refresh(wallet: Wallet) {
        queue.async {
            self._adapterMap[wallet]?.refresh()
        }
    }

}
