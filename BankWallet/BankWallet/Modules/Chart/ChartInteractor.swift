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

    func set(chartType: ChartType) {
        localStorage.chartType = chartType
    }

    func currentRate(coinCode: CoinCode, currencyCode: String) -> Rate? {
        return rateStorage.latestRate(coinCode: coinCode, currencyCode: currencyCode)
    }

    func getRates(coinCode: String, currencyCode: String, chartType: ChartType) {
        apiProvider.getChartRateData(coinCode: coinCode, currencyCode: currencyCode, chartType: chartType).observeOn(MainScheduler.instance).subscribe(onSuccess: { [weak self] data in
            self?.delegate?.didReceive(chartData: data)
        }, onError: { [weak self] error in
            self?.delegate?.onChartError(error)
        }).disposed(by: disposeBag)
    }

    func getMarketCap() {
        apiProvider.getMarketCapData().observeOn(MainScheduler.instance).subscribe(onSuccess: { [weak self] data in
            self?.delegate?.didReceive(marketCapData: data)
        }, onError: { [weak self] error in
            self?.delegate?.onMarketCapError(error)
        }).disposed(by: disposeBag)
    }

}
