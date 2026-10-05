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
    private let localStorage: LocalStorage
    private let updatedSubject = PassthroughSubject<Void, Never>()

    init(localStorage: LocalStorage) {
        self.localStorage = localStorage
    }

    private var userIndicators: [ChartIndicator] {
        // for first time returns default list
        guard let indicatorData = localStorage.chartIndicators else {
            return ChartIndicatorFactory.defaultIndicators
        }

        let decoder = JSONDecoder()
        let results = try? decoder.decode(ChartIndicators.self, from: indicatorData)

        return results?.indicators ?? ChartIndicatorFactory.defaultIndicators
    }
}

extension ChartIndicatorsRepository: IChartIndicatorsRepository {
    var indicators: [ChartIndicator] {
        userIndicators
    }

    func set(indicators: [ChartIndicator]) {
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

        for indicator in userIndicators {
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
        for (index, element) in backup.ma.enumerated() {
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
        for (index, element) in backup.rsi.enumerated() {
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
        for (index, element) in backup.macd.enumerated() {
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
