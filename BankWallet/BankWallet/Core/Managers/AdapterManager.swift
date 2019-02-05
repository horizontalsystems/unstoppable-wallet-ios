import RxSwift

class AdapterManager {
    private let disposeBag = DisposeBag()

    private let adapterFactory: IAdapterFactory
    private let authManager: IAuthManager
    private let coinManager: ICoinManager

    private(set) var adapters: [IAdapter] = []
    let adaptersUpdatedSignal = Signal()

    init(adapterFactory: IAdapterFactory, authManager: IAuthManager, coinManager: ICoinManager) {
        self.adapterFactory = adapterFactory
        self.authManager = authManager
        self.coinManager = coinManager

        coinManager.coinsUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.initAdapters()
                })
                .disposed(by: disposeBag)

        initAdapters()
    }

}

extension AdapterManager: IAdapterManager {

    func initAdapters() {
        guard let authData = authManager.authData else {
            return
        }

        let oldAdapters = adapters

        adapters = coinManager.coins.compactMap { coin in
            if let adapter = adapters.first(where: { $0.coin == coin }) {
                return adapter
            }

            let adapter = adapterFactory.adapter(forCoin: coin, authData: authData)
            adapter?.start()
            return adapter
        }

        for oldAdapter in oldAdapters {
            if !adapters.contains(where: { $0.coin == oldAdapter.coin }) {
                oldAdapter.stop()
            }
        }

        adaptersUpdatedSignal.notify()
    }

    func clear() {
        for adapter in adapters {
            adapter.clear()
        }

        adapters = []
        adaptersUpdatedSignal.notify()
    }

}
