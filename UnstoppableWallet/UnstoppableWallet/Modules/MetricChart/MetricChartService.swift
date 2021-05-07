import UIKit
import RxSwift
import RxCocoa
import XRatesKit
import CoinKit
import CurrencyKit

class MetricChartService {
    private var disposeBag = DisposeBag()

    private let chartFetcher: IMetricChartFetcher
    private let currencyKit: CurrencyKit.Kit

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

    private let stateRelay = PublishRelay<DataStatus<[MetricChartModule.Item]>>()
    private(set) var state: DataStatus<[MetricChartModule.Item]> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(currencyKit: CurrencyKit.Kit, chartFetcher: IMetricChartFetcher) {
        self.currencyKit = currencyKit
        self.chartFetcher = chartFetcher

        fetchChartData()
    }

    private func fetchChartData() {
        disposeBag = DisposeBag()
        state = .loading

        chartFetcher
                .fetchSingle(currencyCode: currencyKit.baseCurrency.code, timePeriod: TimePeriod(chartType: chartType))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] items in
                    self?.state = .completed(items)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension MetricChartService {

    var chartTypes: [ChartType] { [.day, .week, .month] }

    var chartTypeObservable: Observable<ChartType> {
        chartTypeRelay.asObservable()
    }

    var stateObservable: Observable<DataStatus<[MetricChartModule.Item]>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

}
