import Foundation
import RxSwift

class RateManager {
    private let disposeBag = DisposeBag()

    let subject = PublishSubject<Void>()

    private let rateStorage: IRateStorage
    private let transactionRecordStorage: ITransactionRecordStorage
    private let currencyManager: ICurrencyManager
    private let networkManager: IRateNetworkManager
    private let walletManager: IWalletManager

    private let scheduler: ImmediateSchedulerType

    init(rateStorage: IRateStorage, transactionRecordStorage: ITransactionRecordStorage, currencyManager: ICurrencyManager, networkManager: IRateNetworkManager, walletManager: IWalletManager, scheduler: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)) {
        self.rateStorage = rateStorage
        self.transactionRecordStorage = transactionRecordStorage
        self.currencyManager = currencyManager
        self.networkManager = networkManager
        self.walletManager = walletManager

        self.scheduler = scheduler
    }

    private func update(value: Double, coin: Coin, currencyCode: String) {
        rateStorage.save(value: value, coin: coin, currencyCode: currencyCode)
        subject.onNext(())
    }

    private func update(value: Double, transactionHash: String) {
        transactionRecordStorage.set(rate: value, transactionHash: transactionHash)
    }

}

extension RateManager: IRateManager {

    func rate(forCoin coin: Coin, currencyCode: String) -> Rate? {
        return rateStorage.rate(forCoin: coin, currencyCode: currencyCode)
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

    func fillTransactionRates() {
        let currencyCode = currencyManager.baseCurrency.code
        let calendar = Calendar.current

        for record in transactionRecordStorage.nonFilledRecords {
            guard record.timestamp != 0 else {
                continue
            }

            let hash = record.transactionHash
            let date = Date(timeIntervalSince1970: record.timestamp)

            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)

            networkManager.getRate(coin: record.coin, currencyCode: currencyCode, year: year, month: month, day: day, hour: hour, minute: minute)
                    .subscribeOn(scheduler)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] value in
                        self?.update(value: value, transactionHash: hash)
                    })
                    .disposed(by: disposeBag)
        }
    }

}
