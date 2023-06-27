import Foundation
import Chart
import Combine
import HsExtensions

protocol ICountFetcher: AnyObject {
    var count: Int { get }
}

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
                .sink { [weak self] in self?.sync() }
                .store(in: &cancellables)

        sync()
    }

    deinit { print("Deinit \(self)") }

    private func sync() {
        let userIndicators = repository.indicators
        let points = chartPointFetcher.points.data

        items = userIndicators.map { indicator in
            var insufficientData = false
            if let points = points {
                let minimumPoints = indicator.greatestPeriod + Self.minimumIndicatorPoints
                insufficientData = minimumPoints <= points.count
            }
            return IndicatorItem(
                    indicator: indicator,
                    insufficientData: insufficientData)
        }
    }

}
extension ChartIndicatorsService {

    func saveIndicators() {
        repository.indicators = items.map { $0.indicator }
    }

}

extension ChartIndicatorsService {

    struct IndicatorItem {
        let indicator: ChartIndicator
        let insufficientData: Bool
    }

}