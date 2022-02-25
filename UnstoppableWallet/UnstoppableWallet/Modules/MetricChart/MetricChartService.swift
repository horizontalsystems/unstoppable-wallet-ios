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

    private let intervalRelay = PublishRelay<HsTimePeriod>()
    var interval: HsTimePeriod {
        didSet {
            guard interval != oldValue else {
                return
            }
            intervalRelay.accept(interval)
            fetchChartData()
        }
    }

    private let stateRelay = PublishRelay<DataStatus<[MetricChartModule.Item]>>()
    private(set) var state: DataStatus<[MetricChartModule.Item]> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(currencyKit: CurrencyKit.Kit, chartFetcher: IMetricChartFetcher, interval: HsTimePeriod) {
        self.currencyKit = currencyKit
        self.chartFetcher = chartFetcher
        self.interval = interval

        fetchChartData()
        subscribe(fetcherDisposeBag, chartFetcher.needUpdateObservable) { [weak self] in self?.fetchChartData() }
    }

    private func fetchChartData() {
        disposeBag = DisposeBag()
        state = .loading

        chartFetcher
            .fetchSingle(currencyCode: currencyKit.baseCurrency.code, interval: interval)
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

    var intervals: [HsTimePeriod] { chartFetcher.intervals }

    var intervalObservable: Observable<HsTimePeriod> {
        intervalRelay.asObservable()
    }

    var stateObservable: Observable<DataStatus<[MetricChartModule.Item]>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

}
