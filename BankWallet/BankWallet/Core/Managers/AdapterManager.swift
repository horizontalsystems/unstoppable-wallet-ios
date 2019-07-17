import RxSwift

class AdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterFactory: IAdapterFactory
    private let ethereumKitManager: IEthereumKitManager
    private let authManager: IAuthManager
    private let walletManager: IWalletManager

    private(set) var adapters: [IAdapter] = []
    let adaptersUpdatedSignal = Signal()

    init(adapterFactory: IAdapterFactory, ethereumKitManager: IEthereumKitManager, authManager: IAuthManager, walletManager: IWalletManager) {
        self.adapterFactory = adapterFactory
        self.ethereumKitManager = ethereumKitManager
        self.authManager = authManager
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
    }

}
