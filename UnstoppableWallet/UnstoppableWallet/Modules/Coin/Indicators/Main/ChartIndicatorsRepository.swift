import Foundation
import Chart

protocol IChartIndicatorsRepository {
    var indicators: [ChartIndicator] { get set }
}

class ChartIndicatorsRepository {
    private let localStorage: LocalStorage

    init(localStorage: LocalStorage) {
        self.localStorage = localStorage
    }

    private var userIndicators: [ChartIndicator] {
        // for first time returns default list
        guard let indicators = localStorage.chartIndicators else {
            return ChartIndicatorFactory.`default`
        }

        let decoder = JSONDecoder()
        guard let indicators = try? decoder.decode([ChartIndicator].self, from: indicators) else {
            // if local storage has wrong record, returns default
            return ChartIndicatorFactory.`default`
        }

        return indicators
    }
}

extension ChartIndicatorsRepository: IChartIndicatorsRepository {

    var indicators: [ChartIndicator] {
        get {
            userIndicators
        }
        set {
            let encoder = JSONEncoder()
            localStorage.chartIndicators = try? encoder.encode(newValue)
        }
    }

}

extension ChartIndicatorsRepository: ICountFetcher {

    var count: Int {
        indicators.reduce(into: 0) { greatest, indicator in greatest = max(greatest, indicator.greatestPeriod) }
    }

}