import RxSwift

class AdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterFactory: IAdapterFactory
    private let ethereumKitManager: EthereumKitManager
    private let eosKitManager: EosKitManager
    private let binanceKitManager: BinanceKitManager
    private let walletManager: IWalletManager

    private(set) var adapters: [IAdapter] = []
    let adaptersUpdatedSignal = Signal()

    init(adapterFactory: IAdapterFactory, ethereumKitManager: EthereumKitManager, eosKitManager: EosKitManager, binanceKitManager: BinanceKitManager, walletManager: IWalletManager) {
        self.adapterFactory = adapterFactory
        self.ethereumKitManager = ethereumKitManager
        self.eosKitManager = eosKitManager
        self.binanceKitManager = binanceKitManager
        self.walletManager = walletManager

        walletManager.walletsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] wallets in
                    self?.initAdapters(wallets: wallets)
                })
                .disposed(by: disposeBag)
    }

    private func initAdapters(wallets: [Wallet]) {
        let oldAdapters = adapters

        adapters = wallets.compactMap { wallet in
            if let adapter = adapters.first(where: { $0.wallet == wallet }) {
                return adapter
            }

            let adapter = adapterFactory.adapter(wallet: wallet)
            adapter?.start()
            return adapter
        }

        for oldAdapter in oldAdapters {
            if !adapters.contains(where: { $0.wallet == oldAdapter.wallet }) {
                oldAdapter.stop()
            }
        }

        adaptersUpdatedSignal.notify()
    }

}

extension AdapterManager: IAdapterManager {

    func preloadAdapters() {
        initAdapters(wallets: walletManager.wallets)
    }

    func refresh() {
        adapters.forEach { adapter in
            adapter.refresh()
        }

        ethereumKitManager.ethereumKit?.refresh()
        eosKitManager.eosKit?.refresh()
        binanceKitManager.refresh()
    }

}
