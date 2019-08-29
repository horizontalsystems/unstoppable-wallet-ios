import UIKit
import RxSwift

class ChartInteractor {
    weak var delegate: IChartInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let manager: IRateStatsManager
    private let localStorage: ILocalStorage
    private let rateStorage: IRateStorage

    init(manager: IRateStatsManager, localStorage: ILocalStorage, rateStorage: IRateStorage) {
        self.manager = manager
        self.localStorage = localStorage
        self.rateStorage = rateStorage
    }

}

extension ChartInteractor: IChartInteractor {

    var defaultChartType: ChartType {
        return localStorage.chartType ?? .day
    }

    func setDefault(chartType: ChartType) {
        localStorage.chartType = chartType
    }

    func getRateStats(coinCode: String, currencyCode: String) {
        manager.rateStats(coinCode: coinCode, currencyCode: currencyCode)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] data in
                    self?.delegate?.didReceive(chartData: data, rate: self?.rateStorage.latestRate(coinCode: coinCode, currencyCode: currencyCode))
                }, onError: { [weak self] error in
                    self?.delegate?.onError(error)
                }).disposed(by: disposeBag)
    }

}
