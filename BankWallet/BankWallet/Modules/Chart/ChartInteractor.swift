import UIKit
import RxSwift

class ChartInteractor {
    weak var delegate: IChartInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let rateStatsManager: IRateStatsManager
    private var rateStatsSyncer: IRateStatsSyncer
    private let localStorage: ILocalStorage
    private let rateStorage: IRateStorage

    init(rateStatsManager: IRateStatsManager, rateStatsSyncer: IRateStatsSyncer, localStorage: ILocalStorage, rateStorage: IRateStorage) {
        self.rateStatsManager = rateStatsManager
        self.rateStatsSyncer = rateStatsSyncer
        self.localStorage = localStorage
        self.rateStorage = rateStorage
    }

}

extension ChartInteractor: IChartInteractor {

    var defaultChartType: ChartType {
        get {
            return localStorage.chartType ?? .day
        }
        set {
            localStorage.chartType = newValue
        }
    }
    var chartEnabled: Bool {
        get {
            return rateStatsSyncer.chartShown
        }
        set {
            rateStatsSyncer.chartShown = newValue
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

}
