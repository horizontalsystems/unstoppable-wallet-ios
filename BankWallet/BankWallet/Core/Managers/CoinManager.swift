import Foundation
import RxSwift

class CoinManager {
    private let appConfigProvider: IAppConfigProvider
    private let storage: ICoinStorage

    private let disposeBag = DisposeBag()

    var coins = [Coin]() {
        didSet {
            coinsUpdatedSignal.notify()
        }
    }

    let coinsUpdatedSignal = Signal()

    init(appConfigProvider: IAppConfigProvider, storage: ICoinStorage, async: Bool = true) {
        self.appConfigProvider = appConfigProvider
        self.storage = storage

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
        return storage.allCoinsObservable().map { [weak self] coins -> [Coin] in
            var coins = coins
            for coin in self?.appConfigProvider.defaultCoins ?? [] {
                if !coins.contains(coin) {
                    coins.append(coin)
                }
            }
            return coins
        }
    }

    func enableDefaultCoins() {
        storage.save(enabledCoins: appConfigProvider.defaultCoins)
    }

}
