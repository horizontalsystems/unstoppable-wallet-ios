import UIKit
import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit

class MetricChartService {
    private var disposeBag = DisposeBag()
    private var fetcherDisposeBag = DisposeBag()

    private var chartFetcher: IMetricChartFetcher

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

    private let stateRelay = PublishRelay<DataStatus<MetricChartModule.ItemData>>()
    private(set) var state: DataStatus<MetricChartModule.ItemData> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var itemDataMap = [HsTimePeriod: MetricChartModule.ItemData]()

    init(chartFetcher: IMetricChartFetcher, interval: HsTimePeriod) {
        self.chartFetcher = chartFetcher
        self.interval = interval

        subscribe(fetcherDisposeBag, chartFetcher.needUpdateObservable) { [weak self] in self?.fetchChartData() }
    }

    func fetchChartData() {
        disposeBag = DisposeBag()

        if let itemData = itemDataMap[interval] {
            state = .completed(itemData)
            return
        }

        state = .loading

        let interval = interval

        chartFetcher.fetchSingle(interval: interval)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onSuccess: { [weak self] itemData in
                self?.itemDataMap[interval] = itemData
                self?.state = .completed(itemData)
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

    var stateObservable: Observable<DataStatus<MetricChartModule.ItemData>> {
        stateRelay.asObservable()
    }

}
