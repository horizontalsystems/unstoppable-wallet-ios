import Combine
import UIKit
import MarketKit
import CurrencyKit
import HsExtensions

class MetricChartService {
    private var tasks = Set<AnyTask>()
    private var cancellables = Set<AnyCancellable>()

    private var chartFetcher: IMetricChartFetcher

    @DistinctPublished var interval: HsTimePeriod {
        didSet {
            if interval != oldValue {
                fetchChartData()
            }
        }
    }

    @PostPublished private(set) var state: DataStatus<MetricChartModule.ItemData> = .loading

    private var itemDataMap = [HsTimePeriod: MetricChartModule.ItemData]()

    init(chartFetcher: IMetricChartFetcher, interval: HsTimePeriod) {
        self.chartFetcher = chartFetcher
        self.interval = interval

        chartFetcher.needUpdatePublisher
                .sink { [weak self] in self?.fetchChartData() }
                .store(in: &cancellables)
    }

    func fetchChartData() {
        tasks = Set()

        if let itemData = itemDataMap[interval] {
            state = .completed(itemData)
            return
        }

        state = .loading

        Task { [weak self, chartFetcher, interval] in
            do {
                let itemData = try await chartFetcher.fetch(interval: interval)
                self?.itemDataMap[interval] = itemData
                self?.state = .completed(itemData)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

}

extension MetricChartService {

    var valueType: MetricChartModule.ValueType {
        chartFetcher.valueType
    }

    var intervals: [HsTimePeriod] { chartFetcher.intervals }

}
