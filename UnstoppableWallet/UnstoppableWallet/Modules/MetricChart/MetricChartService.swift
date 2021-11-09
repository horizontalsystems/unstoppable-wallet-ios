import UIKit
import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit

class MetricChartService {
    private var disposeBag = DisposeBag()
    private var fetcherDisposeBag = DisposeBag()

    private var chartFetcher: IMetricChartFetcher
    private let currencyKit: CurrencyKit.Kit

    private let chartTypeRelay = PublishRelay<ChartType>()
    var chartType: ChartType {
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

    init(currencyKit: CurrencyKit.Kit, chartFetcher: IMetricChartFetcher, chartType: ChartType) {
        self.currencyKit = currencyKit
        self.chartFetcher = chartFetcher
        self.chartType = chartType

        fetchChartData()
        subscribe(fetcherDisposeBag, chartFetcher.needUpdateObservable) { [weak self] in self?.fetchChartData() }
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

    var chartTypes: [ChartType] { chartFetcher.chartTypes }

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
