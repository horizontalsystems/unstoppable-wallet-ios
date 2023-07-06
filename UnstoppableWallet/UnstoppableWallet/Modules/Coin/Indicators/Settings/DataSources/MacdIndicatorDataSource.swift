import Combine
import Chart

class MacdIndicatorDataSource {
    private let fastPeriodId = "fast-period-input"
    private let slowPeriodId = "slow-period-input"
    private let signalPeriodId = "signal-period-input"

    var fields: [ChartIndicatorSettingsModule.Field] {
        [
            ChartIndicatorSettingsModule.TextField(
                    id: "title-description",
                    text: "chart_indicators.settings.macd.description".localized
            ),
            ChartIndicatorSettingsModule.InputIntegerField(
                    id: fastPeriodId,
                    header: "chart_indicators.settings.macd.fast_period_title".localized,
                    placeholder: defaultIndicator.fast.description,
                    initial: defaultIndicator.fast != indicator.fast ? indicator.fast.description : nil
            ),
            ChartIndicatorSettingsModule.InputIntegerField(
                    id: slowPeriodId,
                    header: "chart_indicators.settings.macd.slow_period_title".localized,
                    placeholder: defaultIndicator.slow.description,
                    initial: defaultIndicator.slow != indicator.slow ? indicator.slow.description : nil
            ),
            ChartIndicatorSettingsModule.InputIntegerField(
                    id: signalPeriodId,
                    header: "chart_indicators.settings.macd.signal_period_title".localized,
                    placeholder: defaultIndicator.signal.description,
                    initial: defaultIndicator.signal != indicator.signal ? indicator.signal.description : nil
            ),
        ]
    }

    private let itemsUpdatedSubject = PassthroughSubject<Void, Never>()
    var currentItems: [ChartIndicatorSettingsModule.ValueItem] {
        [
            .init(id: fastPeriodId, value: fastPeriod),
            .init(id: slowPeriodId, value: slowPeriod),
            .init(id: signalPeriodId, value: signalPeriod),
        ]
    }

    var initialItems: [ChartIndicatorSettingsModule.ValueItem] {
        [
            .init(id: fastPeriodId, value: nil),
            .init(id: slowPeriodId, value: nil),
            .init(id: signalPeriodId, value: nil),
        ]
    }

    private let indicator: MacdIndicator
    private let defaultIndicator: MacdIndicator

    private var stateUpdatedSubject = PassthroughSubject<Void, Never>()
    private(set) var state: IndicatorDataSource.State = .notChanged {
        didSet {
            stateUpdatedSubject.send()
        }
    }

    private var fastPeriod: Int
    private var slowPeriod: Int
    private var signalPeriod: Int

    init(indicator: MacdIndicator, default: MacdIndicator) {
        self.indicator = indicator
        defaultIndicator = `default`
        fastPeriod = indicator.fast
        slowPeriod = indicator.slow
        signalPeriod = indicator.signal

        sync()
    }

    private func sync() {
        itemsUpdatedSubject.send()

        if notEdited {
            state = .notChanged
            return
        }

        var cautions = [IndicatorDataSource.Caution]()
        let wrongPeriodError = fastPeriod >= slowPeriod ? "chart_indicators.settings.macd.slow_fast.error".localized : nil

        if let caution = IndicatorDataSource.periodError(id: fastPeriodId, period: fastPeriod) {
            cautions.append(caution)
        } else if let error = wrongPeriodError {
            cautions.append(IndicatorDataSource.Caution(id: fastPeriodId, error: error))
        }
        if let caution = IndicatorDataSource.periodError(id: slowPeriodId, period: slowPeriod) {
            cautions.append(caution)
        } else if let error = wrongPeriodError {
            cautions.append(IndicatorDataSource.Caution(id: slowPeriodId, error: error))
        }
        if let caution = IndicatorDataSource.periodError(id: signalPeriodId, period: signalPeriod) {
            cautions.append(caution)
        }

        if !cautions.isEmpty {
            state = .failed(cautions)
            return
        }

        state = .success(
                MacdIndicator(
                        id: indicator.id,
                        index: indicator.index,
                        enabled: indicator.enabled,
                        fast: fastPeriod,
                        slow: slowPeriod,
                        signal: signalPeriod,
                        configuration: indicator.configuration
                )
        )
    }

}

extension MacdIndicatorDataSource: IIndicatorDataSource {

    var chartIndicator: ChartIndicator {
        indicator
    }

    var notEdited: Bool {
        indicator.fast == fastPeriod &&
        indicator.slow == slowPeriod &&
        indicator.signal == signalPeriod
    }

    var isDefault: Bool {
        fastPeriod == defaultIndicator.fast &&
        slowPeriod == defaultIndicator.slow &&
        signalPeriod == defaultIndicator.signal
    }

    func set(id: String, value: Any?) {
        switch id {
        case fastPeriodId:                   // change period
            guard let period = value as? String, let intValue = Int(period) else {
                fastPeriod = defaultIndicator.fast
                sync()
                return
            }
            fastPeriod = intValue
            sync()
        case slowPeriodId:                   // change period
            guard let period = value as? String, let intValue = Int(period) else {
                slowPeriod = defaultIndicator.slow
                sync()
                return
            }
            slowPeriod = intValue
            sync()
        case signalPeriodId:                   // change period
            guard let period = value as? String, let intValue = Int(period) else {
                signalPeriod = defaultIndicator.signal
                sync()
                return
            }
            signalPeriod = intValue
            sync()
        default: ()
        }
    }

    func reset() {
        fastPeriod = defaultIndicator.fast
        slowPeriod = defaultIndicator.slow
        signalPeriod = defaultIndicator.signal
        sync()
    }

    var itemsUpdatedPublisher: AnyPublisher<Void, Never> {
        itemsUpdatedSubject.eraseToAnyPublisher()
    }

    var stateUpdatedPublisher: AnyPublisher<(), Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }

}
