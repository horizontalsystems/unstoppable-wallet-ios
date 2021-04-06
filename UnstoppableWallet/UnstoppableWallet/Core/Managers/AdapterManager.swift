import RxSwift
import CoinKit

class AdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterFactory: IAdapterFactory
    private let ethereumKitManager: EthereumKitManager
    private let binanceSmartChainKitManager: BinanceSmartChainKitManager
    private let binanceKitManager: BinanceKitManager
    private let walletManager: IWalletManager

    private let subject = PublishSubject<Void>()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.adapter_manager", qos: .userInitiated)
    private var adapters = [Wallet: IAdapter]()

    init(adapterFactory: IAdapterFactory, ethereumKitManager: EthereumKitManager, binanceSmartChainKitManager: BinanceSmartChainKitManager, binanceKitManager: BinanceKitManager, walletManager: IWalletManager) {
        self.adapterFactory = adapterFactory
        self.ethereumKitManager = ethereumKitManager
        self.binanceSmartChainKitManager = binanceSmartChainKitManager
        self.binanceKitManager = binanceKitManager
        self.walletManager = walletManager

        walletManager.activeWalletsUpdatedObservable
                .observeOn(SerialDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] wallets in
                    self?.initAdapters(wallets: wallets)
                })
                .disposed(by: disposeBag)
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

}

extension AdapterManager: IAdapterManager {

    var adaptersReadyObservable: Observable<Void> {
        subject.asObservable()
    }

    func adapter(for wallet: Wallet) -> IAdapter? {
        queue.sync { adapters[wallet] }
    }

    func adapter(for coin: Coin) -> IAdapter? {
        queue.sync {
            guard let wallet = walletManager.activeWallets.first(where: { $0.coin == coin } ) else {
                return nil
            }

            return adapters[wallet]
        }
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

        ethereumKitManager.evmKit?.refresh()
        binanceSmartChainKitManager.evmKit?.refresh()
        binanceKitManager.refresh()
    }

    func refreshAdapters(wallets: [Wallet]) {
        queue.async {
            wallets.forEach {
                self.adapters[$0]?.stop()
                self.adapters[$0] = nil
            }
        }

        initAdapters(wallets: walletManager.activeWallets)
    }

    func refresh(wallet: Wallet) {
        let adapter = adapters[wallet]

        switch adapter {
        case is BinanceAdapter:
            binanceKitManager.refresh()
        case is BaseEvmAdapter:
            switch wallet.coin.type {
            case .ethereum, .erc20: ethereumKitManager.evmKit?.refresh()
            case .binanceSmartChain, .bep20: binanceSmartChainKitManager.evmKit?.refresh()
            default: ()
            }
        default:
            adapter?.refresh()
        }
    }

}
