import RxSwift

class AdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterFactory: IAdapterFactory
    private let ethereumKitManager: EthereumKitManager
    private let eosKitManager: EosKitManager
    private let binanceKitManager: BinanceKitManager
    private let walletManager: IWalletManager

    private var adaptersMap = [Wallet: IAdapter]()
    let adaptersCreationSignal = Signal()

    init(adapterFactory: IAdapterFactory, ethereumKitManager: EthereumKitManager, eosKitManager: EosKitManager, binanceKitManager: BinanceKitManager, walletManager: IWalletManager) {
        self.adapterFactory = adapterFactory
        self.ethereumKitManager = ethereumKitManager
        self.eosKitManager = eosKitManager
        self.binanceKitManager = binanceKitManager
        self.walletManager = walletManager

        walletManager.walletsUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.initAdapters()
                })
                .disposed(by: disposeBag)
    }

    private func initAdapters() {
        let wallets = walletManager.wallets
        let oldWallets = Array(adaptersMap.keys)

        for wallet in wallets {
            if adaptersMap[wallet] != nil {
                continue
            }

            if let adapter = adapterFactory.adapter(wallet: wallet) {
                adaptersMap[wallet] = adapter
                adapter.start()
            }
        }

        adaptersCreationSignal.notify()

        for oldWallet in oldWallets {
            if !wallets.contains(where: { $0 == oldWallet }) {
                adaptersMap[oldWallet]?.stop()
                adaptersMap.removeValue(forKey: oldWallet)
            }
        }
    }

}

extension AdapterManager: IAdapterManager {

    func preloadAdapters() {
        initAdapters()
    }

    func adapter(for wallet: Wallet) -> IAdapter? {
        return adaptersMap[wallet]
    }

    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter? {
        if let adapter = adaptersMap[wallet], let balanceAdapter = adapter as? IBalanceAdapter {
            return balanceAdapter
        }

        return nil
    }

    func transactionsAdapter(for wallet: Wallet) -> ITransactionsAdapter? {
        if let adapter = adaptersMap[wallet], let transactionsAdapter = adapter as? ITransactionsAdapter {
            return transactionsAdapter
        }

        return nil
    }

    func depositAdapter(for wallet: Wallet) -> IDepositAdapter? {
        if let adapter = adaptersMap[wallet], let depositAdapter = adapter as? IDepositAdapter {
            return depositAdapter
        }

        return nil
    }

    func refresh() {
        for (_, adapter) in adaptersMap {
            adapter.refresh()
        }

        ethereumKitManager.ethereumKit?.refresh()
        eosKitManager.eosKit?.refresh()
        binanceKitManager.refresh()
    }

}
