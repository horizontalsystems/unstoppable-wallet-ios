import Foundation
import Chart
import Combine
import HsExtensions
import MarketKit

class ChartIndicatorsService {
    static let minimumIndicatorPoints = 10

    private var repository: IChartIndicatorsRepository
    private let chartPointFetcher: IChartPointFetcher

    private var cancellables = Set<AnyCancellable>()

    @PostPublished private(set) var items = [IndicatorItem]()

    init(repository: IChartIndicatorsRepository, chartPointFetcher: IChartPointFetcher) {
        self.repository = repository
        self.chartPointFetcher = chartPointFetcher

        chartPointFetcher.pointsUpdatedPublisher
                .sink { [weak self] in
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

}

extension ChartIndicatorsService {

    struct IndicatorItem {
        let indicator: ChartIndicator
        let insufficientData: Bool
    }

}