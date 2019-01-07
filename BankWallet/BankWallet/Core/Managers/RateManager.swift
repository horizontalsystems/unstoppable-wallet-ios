import RxSwift

class RateManager {
    private let disposeBag = DisposeBag()
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)

    private let storage: IRateStorage
    private let networkManager: IRateNetworkManager

    init(storage: IRateStorage, networkManager: IRateNetworkManager) {
        self.storage = storage
        self.networkManager = networkManager
    }

}

extension RateManager: IRateManager {

    func rate(forCoin coinCode: CoinCode, currencyCode: String) -> Rate? {
        return nil
    }

    func refreshRates(coinCodes: [CoinCode], currencyCode: String) {
        for coinCode in coinCodes {
            networkManager.getLatestRate(coinCode: coinCode, currencyCode: currencyCode)
                    .subscribeOn(scheduler)
                    .observeOn(scheduler)
                    .subscribe(onNext: { [weak self] latestRate in
                        let rate = Rate(coinCode: coinCode, currencyCode: currencyCode, value: latestRate.value, timestamp: latestRate.timestamp)
                        self?.storage.save(rate: rate)
                    })
                    .disposed(by: disposeBag)
        }

    }

}
