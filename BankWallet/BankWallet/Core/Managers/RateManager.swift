import Foundation
import RxSwift

class RateManager {
    private let disposeBag = DisposeBag()

    let subject = PublishSubject<Void>()

    private let storage: IRateStorage
    private let currencyManager: ICurrencyManager
    private let networkManager: IRateNetworkManager
    private let walletManager: IWalletManager

    private let scheduler: ImmediateSchedulerType

    init(storage: IRateStorage, currencyManager: ICurrencyManager, networkManager: IRateNetworkManager, walletManager: IWalletManager, scheduler: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)) {
        self.storage = storage
        self.currencyManager = currencyManager
        self.networkManager = networkManager
        self.walletManager = walletManager

        self.scheduler = scheduler
    }

    private func update(value: Double, coin: Coin, currencyCode: String) {
        storage.save(value: value, coin: coin, currencyCode: currencyCode)
        subject.onNext(())
    }

}

extension RateManager: IRateManager {

    func rate(forCoin coin: Coin, currencyCode: String) -> Rate? {
        return storage.rate(forCoin: coin, currencyCode: currencyCode)
    }

    func updateRates() {
        let currencyCode = currencyManager.baseCurrency.code

        for wallet in walletManager.wallets {
            let coin = wallet.coin

            networkManager.getLatestRate(coin: coin, currencyCode: currencyCode)
                    .subscribeOn(scheduler)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] value in
                        self?.update(value: value, coin: coin, currencyCode: currencyCode)
                    })
                    .disposed(by: disposeBag)
        }
    }

}
