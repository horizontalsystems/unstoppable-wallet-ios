import RxSwift

class RateSyncer {
    private let disposeBag = DisposeBag()
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

    init(rateManager: IRateManager, walletManager: IWalletManager, currencyManager: ICurrencyManager, reachabilityManager: IReachabilityManager, timer: Observable<Int>? = nil) {
        let timer = timer ?? Observable<Int>.timer(0, period: 5, scheduler: scheduler)

        Observable.combineLatest(
                walletManager.walletsObservable,
                currencyManager.baseCurrencyObservable,
                reachabilityManager.stateObservable,
                timer
        ) { wallets, baseCurrency, networkConnected, _ -> ([Wallet], Currency, Bool) in
            return (wallets, baseCurrency, networkConnected)
        }
                .subscribeOn(scheduler)
                .observeOn(scheduler)
                .subscribe(onNext: { wallets, baseCurrency, networkConnected in
                    if networkConnected {
                        rateManager.refreshRates(coinCodes: wallets.map { $0.coinCode }, currencyCode: baseCurrency.code)
                    }
                })
                .disposed(by: disposeBag)
    }

}
