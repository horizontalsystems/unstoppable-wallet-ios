import UIKit
import RxSwift
import RxCocoa
import MarketKit
import CoinKit
import CurrencyKit

class MetricChartService {
    private var disposeBag = DisposeBag()

    private var chartFetcherProtocol: IMetricChartFetcher?
    private var chartFetcher: MarketGlobalFetcher?
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
        self.chartFetcherProtocol = chartFetcher

        fetchChartData()
    }

    init(currencyKit: CurrencyKit.Kit, chartFetcher: MarketGlobalFetcher) {
        self.currencyKit = currencyKit
        self.chartFetcher = chartFetcher

        fetchChartData()
    }

    private func fetchChartData() {
        disposeBag = DisposeBag()
        state = .loading

        //todo: implement global data in MarketKit

        var single: RxSwift.Single<[MetricChartModule.Item]>?
        if let chartFetcher = chartFetcher {
            let rawValue: String
            switch TimePeriod(chartType: chartType) {
            case .all: rawValue = "All"
            case .hour1: rawValue = "1h"
            case .dayStart: rawValue = "DayStart"
            case .hour24: rawValue = "24h"
            case .day7: rawValue = "7d"
            case .day14: rawValue = "14d"
            case .day30: rawValue = "30d"
            case .day200: rawValue = "200d"
            case .year1: rawValue = "1y"
            }

            single = chartFetcher.fetchSingle(currencyCode: currencyKit.baseCurrency.code, timePeriod: rawValue)
        }
        if let chartFetcher = chartFetcherProtocol {
            single = chartFetcher.fetchSingle(currencyCode: currencyKit.baseCurrency.code, timePeriod: TimePeriod(chartType: chartType))
        }
        single?
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
