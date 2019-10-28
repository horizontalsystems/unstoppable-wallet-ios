import UIKit
import RxSwift

class ChartInteractor {
    weak var delegate: IChartInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let rateStatsManager: IRateStatsManager
    private let localStorage: ILocalStorage
    private let rateStorage: IRateStorage

    init(rateStatsManager: IRateStatsManager, localStorage: ILocalStorage, rateStorage: IRateStorage) {
        self.rateStatsManager = rateStatsManager
        self.localStorage = localStorage
        self.rateStorage = rateStorage
    }

}

extension ChartInteractor: IChartInteractor {

    var defaultChartType: ChartTypeOld {
        get {
            return localStorage.chartType ?? .day
        }
        set {
            localStorage.chartType = newValue
        }
    }

    func subscribeToChartStats() {
        rateStatsManager.statsObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    switch $0 {
                    case .success(let data):
                        self?.delegate?.didReceive(chartData: data)
                    case .error:
                        self?.delegate?.onError()
                    }
                })
                .disposed(by: disposeBag)
    }

    func subscribeToLatestRate(coinCode: CoinCode, currencyCode: String) {
        rateStorage.latestRateObservable(forCoinCode: coinCode, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didReceive(rate: $0)
                })
                .disposed(by: disposeBag)
    }

    func syncStats(coinCode: CoinCode, currencyCode: String) {
        rateStatsManager.syncStats(coinCode: coinCode, currencyCode: currencyCode)
    }

}
