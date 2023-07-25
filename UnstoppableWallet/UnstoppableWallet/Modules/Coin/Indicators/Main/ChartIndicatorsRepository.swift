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
    private var cancellables = Set<AnyCancellable>()

    private let localStorage: LocalStorage
    private let updatedSubject = PassthroughSubject<Void, Never>()

    private let subscriptionManager: SubscriptionManager

    init(localStorage: LocalStorage, subscriptionManager: SubscriptionManager) {
        self.localStorage = localStorage
        self.subscriptionManager = subscriptionManager

        subscriptionManager.$isAuthenticated
                .sink { [weak self] _ in
                    self?.updatedSubject.send()
                }
                .store(in: &cancellables)
    }

    private var userIndicators: [ChartIndicator] {
        // for first time returns default list
        guard let indicatorData = localStorage.chartIndicators else {
            return ChartIndicatorFactory.defaultIndicators(subscribed: true)
        }

        let decoder = JSONDecoder()
        let results = try? decoder.decode(ChartIndicators.self, from: indicatorData)

        return results?.indicators ?? ChartIndicatorFactory.defaultIndicators(subscribed: true)
    }
}

extension ChartIndicatorsRepository: IChartIndicatorsRepository {

    var indicators: [ChartIndicator] {
        if subscriptionManager.isAuthenticated {
            return userIndicators
        } else {
            return ChartIndicatorFactory.defaultIndicators(subscribed: false)
        }
    }

    func set(indicators: [ChartIndicator]) {
        guard subscriptionManager.isAuthenticated else {
            return
        }

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
