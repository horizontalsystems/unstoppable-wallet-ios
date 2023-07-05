import Combine
import Foundation
import Chart

class ChartIndicatorSettingsViewModel {
    private let dataSource: IIndicatorDataSource

    private var cancellables = Set<AnyCancellable>()

    private let itemsUpdatedSubject = PassthroughSubject<[ChartIndicatorSettingsModule.ValueItem], Never>()
    private let resetToInitialSubject = PassthroughSubject<[ChartIndicatorSettingsModule.ValueItem], Never>()
    private let resetEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    private let buttonEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    private let cautionSubject = PassthroughSubject<[IndicatorDataSource.Caution], Never>()
    private let updateIndicatorSubject = PassthroughSubject<ChartIndicator, Never>()

    init(dataSource: IIndicatorDataSource) {
        self.dataSource = dataSource

        dataSource.stateUpdatedPublisher
            .sink { [weak self] in self?.sync() }
            .store(in: &cancellables)

        dataSource.itemsUpdatedPublisher
            .sink { [weak self] in self?.syncItems() }
            .store(in: &cancellables)

        sync()
    }

    private func syncItems() {
        itemsUpdatedSubject.send(dataSource.currentItems)
    }

    private func sync() {
        resetEnabledSubject.send(!dataSource.isDefault)
        var applyEnabled = false
        var newCautions = [IndicatorDataSource.Caution]()
        switch dataSource.state {
        case .notChanged: ()
        case .success: applyEnabled = true
        case .failed(let cautions): newCautions = cautions
        }
        buttonEnabledSubject.send(applyEnabled)
        cautionSubject.send(newCautions)
    }

}

extension ChartIndicatorSettingsViewModel {

    var title: String {
        let indicator = dataSource.chartIndicator
        switch indicator.abstractType {
        case .ma: return "chart_indicators.settings.ma.title".localized + " \(indicator.index + 1)"
        case .rsi: return "chart_indicators.settings.rsi.title".localized
        case .macd: return "chart_indicators.settings.macd.title".localized
        default: return "Custom"
        }
    }

    var fields: [ChartIndicatorSettingsModule.Field] {
        dataSource.fields
    }

    var itemsUpdatedPublisher: AnyPublisher<[ChartIndicatorSettingsModule.ValueItem], Never> {
        itemsUpdatedSubject.eraseToAnyPublisher()
    }

    var resetToInitialPublisher: AnyPublisher<[ChartIndicatorSettingsModule.ValueItem], Never> {
        resetToInitialSubject.eraseToAnyPublisher()
    }

    var resetEnabledPublisher: AnyPublisher<Bool, Never> {
        resetEnabledSubject.eraseToAnyPublisher()
    }

    var buttonEnabledPublisher: AnyPublisher<Bool, Never> {
        buttonEnabledSubject.eraseToAnyPublisher()
    }

    var cautionPublisher: AnyPublisher<[IndicatorDataSource.Caution], Never> {
        cautionSubject.eraseToAnyPublisher()
    }

    var updateIndicatorPublisher: AnyPublisher<ChartIndicator, Never> {
        updateIndicatorSubject.eraseToAnyPublisher()
    }

    func onChangeText(id: String, value: String?) {
        dataSource.set(id: id, value: value)
    }

    func reset() {
        dataSource.reset()
        resetToInitialSubject.send(dataSource.initialItems)
    }

    func onSelectList(id: String, selected: ChartIndicatorSettingsModule.ListElement) {
        dataSource.set(id: id, value: selected.value)
    }

    func didTapApply() {
        guard case let .success(indicator) = dataSource.state else {
            return
        }

        updateIndicatorSubject.send(indicator)
    }

}
