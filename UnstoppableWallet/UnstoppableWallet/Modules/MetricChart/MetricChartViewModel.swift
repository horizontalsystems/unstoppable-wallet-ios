import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import Chart
import CurrencyKit
import HUD

class MetricChartViewModel {
    private let service: MetricChartService
    private let chartConfiguration: IMetricChartConfiguration
    private let factory: MetricChartFactory
    private let disposeBag = DisposeBag()

    private let pointSelectModeEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let pointSelectedItemRelay = BehaviorRelay<SelectedPointViewItem?>(value: nil)

    private let chartTypeIndexRelay = BehaviorRelay<Int>(value: 0)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let chartInfoRelay = BehaviorRelay<MetricChartViewModel.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    var title: String { chartConfiguration.title }
    var description: String? { chartConfiguration.description }
    var poweredBy: String { chartConfiguration.poweredBy }

    init(service: MetricChartService, chartConfiguration: IMetricChartConfiguration, factory: MetricChartFactory) {
        self.service = service
        self.chartConfiguration = chartConfiguration
        self.factory = factory

        subscribe(disposeBag, service.chartTypeObservable) { [weak self] in self?.sync(chartType: $0) }
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(chartType: service.chartType)
        sync(state: service.state)
    }

    private func sync(chartType: ChartType) {
        chartTypeIndexRelay.accept(service.chartTypes.firstIndex(of: chartType) ?? 0)
    }

    private func sync(state: DataStatus<[MetricChartModule.Item]>) {
        loadingRelay.accept(state.isLoading)
        errorRelay.accept(state.error?.smartDescription)
        if state.error != nil {
            chartInfoRelay.accept(nil)

            return
        }

        guard let items = state.data else {
            chartInfoRelay.accept(nil)
            return
        }

        chartInfoRelay.accept(factory.convert(items: items, chartType: service.chartType, valueType: chartConfiguration.valueType, currency: service.currency))
    }

}

extension MetricChartViewModel {

    var pointSelectModeEnabledDriver: Driver<Bool> {
        pointSelectModeEnabledRelay.asDriver()
    }

    var pointSelectedItemDriver: Driver<SelectedPointViewItem?> {
        pointSelectedItemRelay.asDriver()
    }

    var chartTypeIndexDriver: Driver<Int> {
        chartTypeIndexRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var chartInfoDriver: Driver<MetricChartViewModel.ViewItem?> {
        chartInfoRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var chartTypes: [String] { service.chartTypes.map { $0.title.uppercased() } }

    func onSelectType(at index: Int) {
        let chartTypes = service.chartTypes
        guard chartTypes.count > index else {
            return
        }

        service.chartType = chartTypes[index]
    }

}

extension MetricChartViewModel: IChartViewTouchDelegate {

    public func touchDown() {
        pointSelectModeEnabledRelay.accept(true)
    }

    public func select(item: ChartItem) {
        HapticGenerator.instance.notification(.feedback(.soft))
        pointSelectedItemRelay.accept(factory.selectedPointViewItem(chartItem: item, type: service.chartType, valueType: chartConfiguration.valueType, currency: service.currency))
    }

    public func touchUp() {
        pointSelectModeEnabledRelay.accept(false)
    }

}

extension MetricChartViewModel {

    struct ViewItem {
        let chartData: ChartData

        let chartTrend: MovementTrend

        let currentValue: String?
        let minValue: String?
        let maxValue: String?

        let chartDiff: Decimal?

        let timeline: [ChartTimelineItem]
    }

}
