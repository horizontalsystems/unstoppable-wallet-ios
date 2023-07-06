import Combine
import Chart

class RsiIndicatorDataSource {
    private let periodId = "rsi-period-input"

    var fields: [ChartIndicatorSettingsModule.Field] {
        let isChanged = defaultIndicator.period != indicator.period
        return [
            ChartIndicatorSettingsModule.TextField(
                    id: "title-description",
                    text: "chart_indicators.settings.rsi.description".localized
            ),
            ChartIndicatorSettingsModule.InputIntegerField(
                    id: periodId,
                    header: "chart_indicators.settings.rsi.period_title".localized,
                    placeholder: defaultIndicator.period.description,
                    initial: isChanged ? indicator.period.description : nil
            )
        ]
    }

    var currentItems: [ChartIndicatorSettingsModule.ValueItem] {
        [ .init(id: periodId, value: period) ]
    }

    var initialItems: [ChartIndicatorSettingsModule.ValueItem] {
        [ .init(id: periodId, value: nil) ]
    }

    private let itemsUpdatedSubject = PassthroughSubject<Void, Never>()

    private let defaultIndicator: RsiIndicator
    private let indicator: RsiIndicator

    private var stateUpdatedSubject = PassthroughSubject<Void, Never>()
    private(set) var state: IndicatorDataSource.State = .notChanged {
        didSet {
            stateUpdatedSubject.send()
        }
    }

    private var period: Int

    init(indicator: RsiIndicator, default: RsiIndicator) {
        self.indicator = indicator
        defaultIndicator = `default`
        period = indicator.period

        sync()
    }

    private func sync() {
        itemsUpdatedSubject.send()

        if notEdited {
            state = .notChanged
            return
        }
        if let caution = IndicatorDataSource.periodError(id: periodId, period: period) {
            state = .failed([caution])
            return
        }

        state = .success(
                RsiIndicator(
                        id: indicator.id,
                        index: indicator.index,
                        enabled: indicator.enabled,
                        period: period,
                        configuration: indicator.configuration
                )
        )
    }

}

extension RsiIndicatorDataSource: IIndicatorDataSource {

    var chartIndicator: ChartIndicator {
        indicator
    }

    var notEdited: Bool {
        indicator.period == period
    }

    var isDefault: Bool {
        period == defaultIndicator.period
    }

    func set(id: String, value: Any?) {
        switch id {
        case periodId:                   // change period
            guard let period = value as? String, let intValue = Int(period) else {
                period = defaultIndicator.period
                sync()
                return
            }
            self.period = intValue
            sync()
        default: ()
        }
    }

    func reset() {
        period = defaultIndicator.period
        sync()
    }

    var itemsUpdatedPublisher: AnyPublisher<Void, Never> {
        itemsUpdatedSubject.eraseToAnyPublisher()
    }

    var stateUpdatedPublisher: AnyPublisher<(), Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }

}
