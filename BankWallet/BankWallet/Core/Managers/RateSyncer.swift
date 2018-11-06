import Foundation
import RxSwift

class RateSyncer {
    private let disposeBag = DisposeBag()

    weak var delegate: IRateSyncerDelegate?

    private let networkManager: IRateNetworkManager
    private let scheduler: ImmediateSchedulerType

    init(networkManager: IRateNetworkManager, scheduler: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)) {
        self.networkManager = networkManager
        self.scheduler = scheduler
    }

}

extension RateSyncer: IRateSyncer {

    func sync(coins: [String], currencyCode: String) {
        for coin in coins {
            networkManager.getLatestRate(coin: coin, currencyCode: currencyCode)
                    .subscribeOn(scheduler)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] value in
                        self?.delegate?.didSync(coin: coin, currencyCode: currencyCode, value: value)
                    })
                    .disposed(by: disposeBag)
        }
    }

}
