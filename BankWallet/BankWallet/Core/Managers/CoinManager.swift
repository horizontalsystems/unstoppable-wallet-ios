import RxSwift

class CoinManager {
    private let appConfigProvider: IAppConfigProvider
    private let storage: ICoinStorage
    private let tokenLocalStorage: ITokenLocalStorage

    private let disposeBag = DisposeBag()

    var coins = [Coin]() {
        didSet {
            coinsUpdatedSignal.notify()
        }
    }

    let coinsUpdatedSignal = Signal()

    init(appConfigProvider: IAppConfigProvider, storage: ICoinStorage, tokenLocalStorage: ITokenLocalStorage, async: Bool = true) {
        self.appConfigProvider = appConfigProvider
        self.storage = storage
        self.tokenLocalStorage = tokenLocalStorage

//        let scheduler: ImmediateSchedulerType = async ? ConcurrentDispatchQueueScheduler(qos: .background) : MainScheduler.instance
        storage.enabledCoinsObservable()
//                .subscribeOn(scheduler)
//                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { enabledCoins in
                    self.coins = enabledCoins
                })
                .disposed(by: disposeBag)
    }

}

extension CoinManager: ICoinManager {

    var allCoinsObservable: Observable<[Coin]> {
        let defaultCoins = appConfigProvider.defaultCoins
        var coins = tokenLocalStorage.coins
        for coin in defaultCoins {
            if let index = coins.firstIndex(of: coin) {
                coins.remove(at: index)
            }
        }
        return Observable.just(defaultCoins + coins)
    }

    func enableDefaultCoins() {
        storage.save(enabledCoins: appConfigProvider.defaultCoins)
    }

    func clear() {
        coins = []
        storage.clearCoins()
    }

}
