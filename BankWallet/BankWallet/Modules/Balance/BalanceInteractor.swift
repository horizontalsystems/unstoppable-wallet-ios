import RxSwift

class BalanceInteractor {
    weak var delegate: IBalanceInteractorDelegate?

    private let disposeBag = DisposeBag()
    private var adaptersDisposeBag = DisposeBag()
    private var ratesDisposeBag = DisposeBag()

    private let adapterManager: IAdapterManager
    private let rateStorage: IRateStorage
    private let currencyManager: ICurrencyManager

    init(adapterManager: IAdapterManager, rateStorage: IRateStorage, currencyManager: ICurrencyManager) {
        self.adapterManager = adapterManager
        self.rateStorage = rateStorage
        self.currencyManager = currencyManager
    }

    private func onUpdateAdapters() {
        adaptersDisposeBag = DisposeBag()

        let adapters = adapterManager.adapters

        delegate?.didUpdate(adapters: adapters)

        for adapter in adapters {
            onUpdateBalance(adapter: adapter)
            onUpdateState(adapter: adapter)

            adapter.balanceUpdatedSignal
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.onUpdateBalance(adapter: adapter)
                    })
                    .disposed(by: adaptersDisposeBag)

            adapter.stateUpdatedSignal
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] in
                        self?.onUpdateState(adapter: adapter)
                    })
                    .disposed(by: adaptersDisposeBag)
        }
    }

    private func onUpdateCurrency() {
        delegate?.didUpdate(currency: currencyManager.baseCurrency)
    }

    private func onUpdateBalance(adapter: IAdapter) {
        delegate?.didUpdate(balance: adapter.balance, coinCode: adapter.coin.code)
    }

    private func onUpdateState(adapter: IAdapter) {
        delegate?.didUpdate(state: adapter.state, coinCode: adapter.coin.code)
    }

}

extension BalanceInteractor: IBalanceInteractor {

    func initAdapters() {
        onUpdateAdapters()
        onUpdateCurrency()

        adapterManager.adaptersUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateAdapters()
                })
                .disposed(by: disposeBag)

        currencyManager.baseCurrencyUpdatedSignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.onUpdateCurrency()
                })
                .disposed(by: disposeBag)
    }

    func fetchRates(currencyCode: String, coinCodes: [CoinCode]) {
        ratesDisposeBag = DisposeBag()

        for coinCode in coinCodes {
            rateStorage.latestRateObservable(forCoinCode: coinCode, currencyCode: currencyCode)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] rate in
                        self?.delegate?.didUpdate(rate: rate)
                    })
                    .disposed(by: ratesDisposeBag)
        }
    }

}
