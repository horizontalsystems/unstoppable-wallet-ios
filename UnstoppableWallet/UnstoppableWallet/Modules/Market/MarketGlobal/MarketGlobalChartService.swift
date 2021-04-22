import UIKit
import RxSwift
import RxCocoa
import XRatesKit
import CoinKit
import CurrencyKit

class MarketGlobalChartService {
    private var disposeBag = DisposeBag()

    private let rateManager: IRateManager
    private let currencyKit: ICurrencyKit
    let metricsType: MarketGlobalModule.MetricsType

    private let chartTypeRelay = PublishRelay<ChartType>()
    var chartType: ChartType = .day {
        didSet {
            guard chartType != oldValue else {
                return
            }
            chartTypeRelay.accept(chartType)
            fetchChartData()
        }
    }

    private let stateRelay = PublishRelay<DataStatus<[GlobalCoinMarketPoint]>>()
    private(set) var state: DataStatus<[GlobalCoinMarketPoint]> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(rateManager: IRateManager, currencyKit: ICurrencyKit, metricsType: MarketGlobalModule.MetricsType) {
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.metricsType = metricsType

        fetchChartData()
    }

    private func fetchChartData() {
        disposeBag = DisposeBag()
        state = .loading

        rateManager
                .globalMarketInfoPointsSingle(currencyCode: currencyKit.baseCurrency.code, timePeriod: TimePeriod(chartType: chartType))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] chartPoints in
                    self?.state = .completed(chartPoints)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension MarketGlobalChartService {

    var chartTypes: [ChartType] { [.day, .week, .month] }

    var chartTypeObservable: Observable<ChartType> {
        chartTypeRelay.asObservable()
    }

    var stateObservable: Observable<DataStatus<[GlobalCoinMarketPoint]>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

}
