import Foundation
import Chart
import Combine
import HsExtensions
import MarketKit

class ChartIndicatorsService {
    static let minimumIndicatorPoints = 10

    private var repository: IChartIndicatorsRepository
    private let chartPointFetcher: IChartPointFetcher
    private let subscriptionManager: SubscriptionManager

    private var cancellables = Set<AnyCancellable>()

    @PostPublished private(set) var isLocked = false
    @PostPublished private(set) var items = [IndicatorItem]()

    init(repository: IChartIndicatorsRepository, chartPointFetcher: IChartPointFetcher, subscriptionManager: SubscriptionManager) {
        self.repository = repository
        self.chartPointFetcher = chartPointFetcher
        self.subscriptionManager = subscriptionManager

        repository.updatedPublisher
                .sink { [weak self] in
                    self?.sync()
                }
                .store(in: &cancellables)

        chartPointFetcher.pointsUpdatedPublisher
                .sink { [weak self] in
                    self?.sync()
                }
                .store(in: &cancellables)

        subscriptionManager.$isAuthenticated
                .sink { [weak self] _ in
                    self?.sync()
                }
                .store(in: &cancellables)

        sync()
    }

    private func calculateInsufficient(indicator: ChartIndicator, points: [ChartPoint]?) -> Bool {
        var insufficientData = false
        if let points = points, indicator.enabled {
            let minimumPoints = indicator.greatestPeriod + Self.minimumIndicatorPoints
            insufficientData = minimumPoints <= points.count
        }
        return insufficientData
    }

    private func sync() {
        isLocked = !subscriptionManager.isAuthenticated
        let userIndicators = repository.indicators
        let points = chartPointFetcher.points.data

        items = userIndicators.map { indicator in
            IndicatorItem(
                    indicator: indicator,
                    insufficientData: calculateInsufficient(indicator: indicator, points: points))
        }
    }

}

extension ChartIndicatorsService {

    func set(enabled: Bool, id: String, index: Int) {
        guard let itemIndex = items.firstIndex(where: { $0.indicator.id == id && $0.indicator.index == index }) else {
            return
        }

        let newItemIndicator = items[itemIndex].indicator
        newItemIndicator.enabled = enabled

        // if we have single-view items on same area and try it enable this one, we must found and disable all others
        if enabled {
            for (index, item) in items.enumerated() {
                guard index != itemIndex else {
                    continue
                }

                if item.indicator.onChart == newItemIndicator.onChart, item.indicator.single {
                    item.indicator.enabled = false
                }
            }
        }

        items[itemIndex] = IndicatorItem(
                indicator: newItemIndicator,
                insufficientData: calculateInsufficient(
                        indicator: newItemIndicator,
                        points: chartPointFetcher.points.data
                )
        )
    }

    func saveIndicators() {
        repository.set(indicators: items.map { $0.indicator })
    }

    func indicator(id: String, index: Int) -> ChartIndicator? {
        guard let index = items.firstIndex(where: { $0.indicator.id == id && $0.indicator.index == index }) else {
            return nil
        }

        return items[index].indicator
    }

    func update(indicator: ChartIndicator) {
        guard let index = items.firstIndex(where: { $0.indicator.id == indicator.id && $0.indicator.index == indicator.index }) else {
            return
        }

        items[index] = IndicatorItem(indicator: indicator, insufficientData: items[index].insufficientData)
    }

}

extension ChartIndicatorsService {

    struct IndicatorItem {
        let indicator: ChartIndicator
        let insufficientData: Bool
    }

}
