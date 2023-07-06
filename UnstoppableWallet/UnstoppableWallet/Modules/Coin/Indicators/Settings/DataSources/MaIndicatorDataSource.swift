import Combine
import Chart

class MaIndicatorDataSource {
    private let typeId = "ma-type-list"
    private let periodId = "ma-period-input"

    private let maTypeElements = MaIndicator.MaType.allCases.enumerated().map {
        ChartIndicatorSettingsModule.ListElement(id: $0, title: $1.rawValue.uppercased(), value: $1)
    }

    private func element(of type: MaIndicator.MaType) -> ChartIndicatorSettingsModule.ListElement {
        maTypeElements[MaIndicator.MaType.allCases.firstIndex(of: type) ?? 0]
    }

    var fields: [ChartIndicatorSettingsModule.Field] {
        let isChanged = defaultIndicator.period != indicator.period
        return [
            ChartIndicatorSettingsModule.TextField(
                    id: "title-description",
                    text: "chart_indicators.settings.ma.description".localized
            ),
            ChartIndicatorSettingsModule.ListField(
                    id: typeId,
                    header: nil,
                    title: "chart_indicators.settings.ma.type_title".localized,
                    elements: maTypeElements,
                    initial: element(of: type)
            ),
            ChartIndicatorSettingsModule.InputIntegerField(
                    id: periodId,
                    header: "chart_indicators.settings.ma.period_title".localized,
                    placeholder: defaultIndicator.period.description,
                    initial: isChanged ? indicator.period.description : nil
            )
        ]
    }

    private let itemsUpdatedSubject = PassthroughSubject<Void, Never>()
    var currentItems: [ChartIndicatorSettingsModule.ValueItem] {
        [
            .init(id: typeId, value: element(of: type)),
            .init(id: periodId, value: period),
        ]
    }

    var initialItems: [ChartIndicatorSettingsModule.ValueItem] {
        [
            .init(id: typeId, value: element(of: indicator.type)),
            .init(id: periodId, value: nil),
        ]
    }

    private let indicator: MaIndicator
    private let defaultIndicator: MaIndicator

    private var stateUpdatedSubject = PassthroughSubject<Void, Never>()
    private(set) var state: IndicatorDataSource.State = .notChanged {
        didSet {
            stateUpdatedSubject.send()
        }
    }

    private var type: MaIndicator.MaType
    private var period: Int

    init(indicator: MaIndicator, default: MaIndicator) {
        self.indicator = indicator
        defaultIndicator = `default`

        type = indicator.type
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
                MaIndicator(
                        id: indicator.id,
                        index: indicator.index,
                        enabled: indicator.enabled,
                        period: period,
                        type: type,
                        configuration: indicator.configuration
                )
        )
    }

}

extension MaIndicatorDataSource: IIndicatorDataSource {

    var chartIndicator: ChartIndicator {
        indicator
    }

    var notEdited: Bool {
        indicator.type == type &&
            indicator.period == period
    }

    var isDefault: Bool {
        type == defaultIndicator.type &&
        period == defaultIndicator.period
    }

    func set(id: String, value: Any?) {
        switch id {
        case typeId:                     // change type
            guard let maType = value as? MaIndicator.MaType else {
                type = defaultIndicator.type
                sync()
                return
            }
            type = maType
            sync()
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
        type = defaultIndicator.type
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
