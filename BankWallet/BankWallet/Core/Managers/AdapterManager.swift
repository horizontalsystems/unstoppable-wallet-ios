import RxSwift

class AdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterFactory: IAdapterFactory
    private let ethereumKitManager: EthereumKitManager
    private let eosKitManager: EosKitManager
    private let binanceKitManager: BinanceKitManager
    private let walletManager: IWalletManager
    private let derivationSettingsManager: IDerivationSettingsManager
    private let initialSyncSettingsManager: IInitialSyncSettingsManager

    private let subject = PublishSubject<Void>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.adapter_manager", qos: .userInitiated)
    private var adapters = [Wallet: IAdapter]()

    init(adapterFactory: IAdapterFactory, ethereumKitManager: EthereumKitManager, eosKitManager: EosKitManager, binanceKitManager: BinanceKitManager, walletManager: IWalletManager, derivationSettingsManager: IDerivationSettingsManager, initialSyncSettingsManager: IInitialSyncSettingsManager) {
        self.adapterFactory = adapterFactory
        self.ethereumKitManager = ethereumKitManager
        self.eosKitManager = eosKitManager
        self.binanceKitManager = binanceKitManager
        self.walletManager = walletManager
        self.derivationSettingsManager = derivationSettingsManager
        self.initialSyncSettingsManager = initialSyncSettingsManager

        let scheduler = SerialDispatchQueueScheduler(qos: .utility)

        walletManager.walletsUpdatedObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] wallets in
                    self?.initAdapters(wallets: wallets)
                })
                .disposed(by: disposeBag)

        derivationSettingsManager.derivationUpdatedObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] coinType in
                    self?.onUpdateDerivation(coinType: coinType)
                })
                .disposed(by: disposeBag)

        initialSyncSettingsManager.syncModeUpdatedObservable
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] coinType in
                    self?.onUpdateSyncMode(coinType: coinType)
                })
                .disposed(by: disposeBag)
    }

    private func onUpdateDerivation(coinType: CoinType) {
        refreshAdapters(walletsForUpdate: walletManager.wallets.filter { $0.coin.type == coinType })
    }

    private func onUpdateSyncMode(coinType: CoinType) {
        refreshAdapters(walletsForUpdate: walletManager.wallets.filter { $0.coin.type == coinType && $0.account.origin == .restored })
    }

    private func initAdapters(wallets: [Wallet]) {
        var newAdapters = queue.sync { adapters }

        for wallet in wallets {
            guard newAdapters[wallet] == nil else {
                continue
            }

            if let adapter = adapterFactory.adapter(wallet: wallet) {
                newAdapters[wallet] = adapter
                adapter.start()
            }
        }

        var removedAdapters = [IAdapter]()

        for wallet in Array(newAdapters.keys) {
            guard !wallets.contains(wallet), let adapter = newAdapters.removeValue(forKey: wallet) else {
                continue
            }

            removedAdapters.append(adapter)
        }

        queue.async {
            self.adapters = newAdapters
            self.subject.onNext(())
        }

        removedAdapters.forEach { adapter in
            adapter.stop()
        }
    }

    private func refreshAdapters(walletsForUpdate: [Wallet]) {
        guard !walletsForUpdate.isEmpty else {
            return
        }

        queue.async {
            walletsForUpdate.forEach { self.adapters[$0] = nil }
        }

        initAdapters(wallets: walletManager.wallets)
    }
}

extension AdapterManager: IAdapterManager {

    var adaptersReadyObservable: Observable<Void> {
        subject.asObservable()
    }

    func adapter(for wallet: Wallet) -> IAdapter? {
        queue.sync { adapters[wallet] }
    }

    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter? {
        queue.sync { adapters[wallet] as? IBalanceAdapter }
    }

    func transactionsAdapter(for wallet: Wallet) -> ITransactionsAdapter? {
        queue.sync { adapters[wallet] as? ITransactionsAdapter }
    }

    func depositAdapter(for wallet: Wallet) -> IDepositAdapter? {
        queue.sync { adapters[wallet] as? IDepositAdapter }
    }

    func refresh() {
        queue.async {
            for adapter in self.adapters.values {
                adapter.refresh()
            }
        }

        ethereumKitManager.ethereumKit?.refresh()
        eosKitManager.eosKit?.refresh()
        binanceKitManager.refresh()
    }

}
