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

    private let intervalIndexRelay = BehaviorRelay<Int>(value: 0)
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

        subscribe(disposeBag, service.intervalObservable) { [weak self] in self?.sync(interval: $0) }
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(interval: service.interval)
        sync(state: service.state)
    }

    private func sync(interval: HsTimePeriod) {
        intervalIndexRelay.accept(service.intervals.firstIndex(of: interval) ?? 0)
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

        chartInfoRelay.accept(factory.convert(items: items, interval: service.interval, valueType: chartConfiguration.valueType, currency: service.currency))
    }

}

extension MetricChartViewModel {

    var pointSelectModeEnabledDriver: Driver<Bool> {
        pointSelectModeEnabledRelay.asDriver()
    }

    var pointSelectedItemDriver: Driver<SelectedPointViewItem?> {
        pointSelectedItemRelay.asDriver()
    }

    var intervalIndexDriver: Driver<Int> {
        intervalIndexRelay.asDriver()
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

    var chartTypes: [String] { service.intervals.map { $0.title.uppercased() } }

    func onSelectType(at index: Int) {
        let chartTypes = service.intervals
        guard chartTypes.count > index else {
            return
        }

        service.interval = chartTypes[index]
    }

}

extension MetricChartViewModel: IChartViewTouchDelegate {

    public func touchDown() {
        pointSelectModeEnabledRelay.accept(true)
    }

    public func select(item: ChartItem) {
        HapticGenerator.instance.notification(.feedback(.soft))
        pointSelectedItemRelay.accept(factory.selectedPointViewItem(chartItem: item, valueType: chartConfiguration.valueType, currency: service.currency))
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
