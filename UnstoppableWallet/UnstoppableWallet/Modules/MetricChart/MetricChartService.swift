import Combine
import HsExtensions
import MarketKit
import UIKit

class MetricChartService {
    private var tasks = Set<AnyTask>()
    private var cancellables = Set<AnyCancellable>()

    private var chartFetcher: IMetricChartFetcher

    @DistinctPublished var interval: HsPeriodType {
        didSet {
            if interval != oldValue {
                fetchChartData()
            }
        }
    }

    @DistinctPublished var intervals: [HsPeriodType]

    @PostPublished private(set) var state: DataStatus<MetricChartModule.ItemData> = .loading

    private var itemDataMap = [HsPeriodType: MetricChartModule.ItemData]()

    init(chartFetcher: IMetricChartFetcher, interval: HsPeriodType) {
        self.chartFetcher = chartFetcher
        self.interval = interval

        intervals = chartFetcher.intervals

        chartFetcher.needUpdatePublisher
            .sink { [weak self] in self?.fetchChartData() }
            .store(in: &cancellables)
        chartFetcher.needUpdateIntervals
            .sink { [weak self] in self?.updateIntervals() }
            .store(in: &cancellables)
    }

    private func updateIntervals() {
        intervals = chartFetcher.intervals
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
}
