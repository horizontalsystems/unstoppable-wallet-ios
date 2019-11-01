import RxSwift

class AdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterFactory: IAdapterFactory
    private let ethereumKitManager: EthereumKitManager
    private let eosKitManager: EosKitManager
    private let binanceKitManager: BinanceKitManager
    private let walletManager: IWalletManager

    private var adapters = SynchronizedDictionary<Wallet, IAdapter>()
    let adaptersReadySignal = Signal()

    init(adapterFactory: IAdapterFactory, ethereumKitManager: EthereumKitManager, eosKitManager: EosKitManager, binanceKitManager: BinanceKitManager, walletManager: IWalletManager) {
        self.adapterFactory = adapterFactory
        self.ethereumKitManager = ethereumKitManager
        self.eosKitManager = eosKitManager
        self.binanceKitManager = binanceKitManager
        self.walletManager = walletManager

        walletManager.walletsUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(SerialDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] wallets in
                    self?.initAdapters(wallets: wallets)
                })
                .disposed(by: disposeBag)
    }

    private func initAdapters(wallets: [Wallet]) {
        var newAdapters: [Wallet: IAdapter] = adapters.rawDictionary

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

        adapters.rawDictionary = newAdapters
        adaptersReadySignal.notify()

        removedAdapters.forEach { adapter in
            adapter.stop()
        }
    }

}

extension AdapterManager: IAdapterManager {

    func adapter(for wallet: Wallet) -> IAdapter? {
        adapters[wallet]
    }

    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter? {
        adapters[wallet] as? IBalanceAdapter
    }

    func transactionsAdapter(for wallet: Wallet) -> ITransactionsAdapter? {
        adapters[wallet] as? ITransactionsAdapter
    }

    func depositAdapter(for wallet: Wallet) -> IDepositAdapter? {
        adapters[wallet] as? IDepositAdapter
    }

    func refresh() {
        for (_, adapter) in adapters.rawDictionary {
            adapter.refresh()
        }

        ethereumKitManager.ethereumKit?.refresh()
        eosKitManager.eosKit?.refresh()
        binanceKitManager.refresh()
    }

}
