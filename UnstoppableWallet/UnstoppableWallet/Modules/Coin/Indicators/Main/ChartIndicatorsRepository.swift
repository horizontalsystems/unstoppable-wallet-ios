import Foundation
import Combine
import Chart

protocol IChartIndicatorsRepository {
    var indicators: [ChartIndicator] { get }
    var updatedPublisher: AnyPublisher<Void, Never> { get }
    var extendedPointCount: Int { get }

    func set(indicators: [ChartIndicator])
}

class ChartIndicatorsRepository {
    private let localStorage: LocalStorage
    private let updatedSubject = PassthroughSubject<Void, Never>()

    init(localStorage: LocalStorage) {
        self.localStorage = localStorage
    }

    private var userIndicators: [ChartIndicator] {
        // for first time returns default list
        guard let indicatorData = localStorage.chartIndicators else {
            return ChartIndicatorFactory.default
        }

        let decoder = JSONDecoder()
        let results = try? decoder.decode(ChartIndicators.self, from: indicatorData)

        return results?.indicators ?? ChartIndicatorFactory.default
    }
}

extension ChartIndicatorsRepository: IChartIndicatorsRepository {

    var indicators: [ChartIndicator] {
        userIndicators
    }

    func set(indicators: [ChartIndicator]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let oldIndicators = userIndicators
        if indicators != oldIndicators {
            localStorage.chartIndicators = try? encoder.encode(ChartIndicators(with: indicators))
            updatedSubject.send()
        }
    }

    var updatedPublisher: AnyPublisher<Void, Never> {
        updatedSubject.eraseToAnyPublisher()
    }

    var extendedPointCount: Int {
        indicators.reduce(into: 0) { greatest, indicator in
            greatest = indicator.enabled ? max(greatest, indicator.greatestPeriod) : greatest
        }
    }

}
