import RxSwift

class AdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterFactory: IAdapterFactory
    private let ethereumKitManager: EthereumKitManager
    private let eosKitManager: EosKitManager
    private let binanceKitManager: BinanceKitManager
    private let walletManager: IWalletManager

    private var adaptersMap = [Wallet: IAdapter]()
    private let adaptersQueue = DispatchQueue(label: "Adapters Queue", qos: .background)
    let adaptersReadySignal = Signal()

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
        adaptersQueue.async {
            let wallets = self.walletManager.wallets
            let oldWallets = Array(self.adaptersMap.keys)
            
            for wallet in wallets {
                if self.adaptersMap[wallet] != nil {
                    continue
                }
                
                if let adapter = self.adapterFactory.adapter(wallet: wallet) {
                    self.adaptersMap[wallet] = adapter
                    adapter.start()
                }
            }
            
            self.adaptersReadySignal.notify()
            
            for oldWallet in oldWallets {
                if !wallets.contains(where: { $0 == oldWallet }) {
                    self.adaptersMap[oldWallet]?.stop()
                    self.adaptersMap.removeValue(forKey: oldWallet)
                }
            }
        }
    }

}

extension AdapterManager: IAdapterManager {

    func adapter(for wallet: Wallet) -> IAdapter? {
        return adaptersQueue.sync { adaptersMap[wallet] }
    }

    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter? {
        return adaptersQueue.sync {
            if let adapter = adaptersMap[wallet], let balanceAdapter = adapter as? IBalanceAdapter {
                return balanceAdapter
            }

            return nil
        }
    }

    func transactionsAdapter(for wallet: Wallet) -> ITransactionsAdapter? {
        return adaptersQueue.sync {
            if let adapter = adaptersMap[wallet], let transactionsAdapter = adapter as? ITransactionsAdapter {
                return transactionsAdapter
            }

            return nil
        }
    }

    func depositAdapter(for wallet: Wallet) -> IDepositAdapter? {
        return adaptersQueue.sync {
            if let adapter = adaptersMap[wallet], let depositAdapter = adapter as? IDepositAdapter {
                return depositAdapter
            }

            return nil
        }
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
