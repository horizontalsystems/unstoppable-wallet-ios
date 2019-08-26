import UIKit
import RxSwift

class ChartInteractor {
    weak var delegate: IChartInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let apiProvider: IRatesStatsApiProvider
    private let localStorage: ILocalStorage
    private let rateStorage: IRateStorage

    init(apiProvider: IRatesStatsApiProvider, localStorage: ILocalStorage, rateStorage: IRateStorage) {
        self.apiProvider = apiProvider
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
        apiProvider.getRateStatsData(coinCode: coinCode, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] data in
                    self?.delegate?.didReceive(rateStats: data, rate: self?.rateStorage.latestRate(coinCode: coinCode, currencyCode: currencyCode))
                }, onError: { [weak self] error in
                self?.delegate?.onError(error)
                }).disposed(by: disposeBag)
    }

}
