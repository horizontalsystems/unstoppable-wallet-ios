import RxSwift
import RxRelay
import MarketKit

class AdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterFactory: AdapterFactory
    private let walletManager: WalletManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let initialSyncSettingsManager: InitialSyncSettingsManager

    private let adaptersReadyRelay = PublishRelay<[Wallet: IAdapter]>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.adapter_manager", qos: .userInitiated)
    private var _adapterMap = [Wallet: IAdapter]()

    init(adapterFactory: AdapterFactory, walletManager: WalletManager, evmBlockchainManager: EvmBlockchainManager, initialSyncSettingsManager: InitialSyncSettingsManager) {
        self.adapterFactory = adapterFactory
        self.walletManager = walletManager
        self.evmBlockchainManager = evmBlockchainManager
        self.initialSyncSettingsManager = initialSyncSettingsManager

        walletManager.activeWalletsUpdatedObservable
                .observeOn(SerialDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] wallets in
                    self?.initAdapters(wallets: wallets)
                })
                .disposed(by: disposeBag)

        for blockchain in evmBlockchainManager.allBlockchains {
            subscribe(disposeBag, evmBlockchainManager.evmKitManager(blockchain: blockchain).evmKitUpdatedObservable) { [weak self] in self?.handleUpdatedEvmKit(blockchain: blockchain) }
        }
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

    private func handleUpdatedEvmKit(blockchain: EvmBlockchain) {
        let wallets = queue.sync { _adapterMap.keys }
        refreshAdapters(wallets: wallets.filter { wallet in
            blockchain.supports(coinType: wallet.coinType)
        })
    }

    private func handleUpdated(setting: InitialSyncSetting) {
        let wallets = queue.sync { _adapterMap.keys }

        refreshAdapters(wallets: wallets.filter {
            setting.coinType == $0.coinType && $0.account.origin == .restored
        })
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

    func adapter(for platformCoin: PlatformCoin) -> IAdapter? {
        queue.sync {
            guard let wallet = walletManager.activeWallets.first(where: { $0.platformCoin == platformCoin } ) else {
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
            for blockchain in self.evmBlockchainManager.allBlockchains {
                self.evmBlockchainManager.evmKitManager(blockchain: blockchain).evmKitWrapper?.evmKit.refresh()
            }
            var binanceKitUpdated = false

            for (wallet, adapter) in self._adapterMap {
                switch wallet.coinType {
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
