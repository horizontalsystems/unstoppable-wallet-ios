import Foundation
import RxSwift

class ExchangeRateManager {
    private let disposeBag = DisposeBag()

    private let databaseManager: IDatabaseManager
    private let networkManager: INetworkManager
    private let updateSubject: PublishSubject<[String: Double]>

    init(databaseManager: IDatabaseManager, networkManager: INetworkManager, updateSubject: PublishSubject<[String: Double]>) {
        self.databaseManager = databaseManager
        self.networkManager = networkManager
        self.updateSubject = updateSubject
    }

    func refresh() {
        networkManager.getExchangeRates().subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] rates in
            self?.databaseManager.truncateExchangeRates()
            self?.databaseManager.insert(exchangeRates: rates)
            self?.updateSubject.onNext(rates)
        })
    }

}
