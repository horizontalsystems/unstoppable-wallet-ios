import Chart
import Combine
import Foundation

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

        if indicators != userIndicators {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
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

extension ChartIndicatorsRepository {
    var backup: BackupIndicators {
        var ma = [BackupMaIndicator]()
        var rsi = [BackupRsiIndicator]()
        var macd = [BackupMacdIndicator]()

        userIndicators.forEach { indicator in
            switch indicator {
            case let indicator as MaIndicator:
                ma.append(BackupMaIndicator(
                    period: indicator.period,
                    type: indicator.type.rawValue,
                    enabled: indicator.enabled
                ))
            case let indicator as RsiIndicator:
                rsi.append(BackupRsiIndicator(
                    period: indicator.period,
                    enabled: indicator.enabled
                ))
            case let indicator as MacdIndicator:
                macd.append(BackupMacdIndicator(
                    slow: indicator.slow,
                    fast: indicator.fast,
                    signal: indicator.signal,
                    enabled: indicator.enabled
                ))
            default: ()
            }
        }
        return BackupIndicators(
                ma: ma,
                rsi: rsi,
                macd: macd
        )
    }

    func restore(backup: BackupIndicators) {
        var indicators = [ChartIndicator]()
        backup.ma.enumerated().forEach { index, element in
            indicators.append(
                MaIndicator(
                    id: "MA",
                    index: index,
                    enabled: element.enabled,
                    period: element.period,
                    type: MaIndicator.MaType(rawValue: element.type) ?? .sma,
                    onChart: true,
                    single: false,
                    configuration: ChartIndicatorFactory.maConfiguration(index)
                )
            )
        }
        backup.rsi.enumerated().forEach { index, element in
            indicators.append(
                RsiIndicator(
                    id: "RSI",
                    index: index,
                    enabled: element.enabled,
                    period: element.period,
                    onChart: false,
                    single: true,
                    configuration: ChartIndicatorFactory.rsiConfiguration
                )
            )
        }
        backup.macd.enumerated().forEach { index, element in
            indicators.append(
                    MacdIndicator(
                            id: "MACD",
                            index: index,
                            enabled: element.enabled,
                            fast: element.fast,
                            slow: element.slow,
                            signal: element.signal,
                            onChart: false,
                            single: true,
                            configuration: ChartIndicatorFactory.macdConfiguration
                    )
            )
        }
        set(indicators: indicators)
    }
}

extension ChartIndicatorsRepository {
    struct BackupIndicators: Codable {
        let ma: [BackupMaIndicator]
        let rsi: [BackupRsiIndicator]
        let macd: [BackupMacdIndicator]
    }

    struct BackupMaIndicator: Codable {
        let period: Int
        let type: String
        let enabled: Bool
    }

    struct BackupRsiIndicator: Codable {
        let period: Int
        let enabled: Bool
    }

    struct BackupMacdIndicator: Codable {
        let slow: Int
        let fast: Int
        let signal: Int
        let enabled: Bool
    }
}
