import Foundation
import RxSwift
import RxRelay
import RxCocoa
import XRatesKit
import Chart
import CurrencyKit
import HUD

class MarketGlobalChartViewModel {
    private let service: MarketGlobalChartService
    private let factory: MarketGlobalChartFactory
    private let disposeBag = DisposeBag()

    private let pointSelectModeEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let pointSelectedItemRelay = BehaviorRelay<SelectedPointViewItem?>(value: nil)

    private let chartTypeIndexRelay = BehaviorRelay<Int>(value: 0)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let chartInfoRelay = BehaviorRelay<MarketGlobalChartViewModel.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    var title: String { service.metricsType.title }
    var description: String { service.metricsType.description }

    init(service: MarketGlobalChartService, factory: MarketGlobalChartFactory) {
        self.service = service
        self.factory = factory

        subscribe(disposeBag, service.chartTypeObservable) { [weak self] in self?.sync(chartType: $0) }
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(chartType: service.chartType)
        sync(state: service.state)
    }

    private func sync(chartType: ChartType) {
        chartTypeIndexRelay.accept(service.chartTypes.firstIndex(of: chartType) ?? 0)
    }

    private func sync(state: DataStatus<[GlobalCoinMarketPoint]>) {
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

        chartInfoRelay.accept(factory.convert(items: items, chartType: service.chartType, metricsType: service.metricsType, currency: service.currency))
    }

}

extension MarketGlobalChartViewModel {

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

    var chartInfoDriver: Driver<MarketGlobalChartViewModel.ViewItem?> {
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

extension MarketGlobalChartViewModel: IChartViewTouchDelegate {

    public func touchDown() {
        pointSelectModeEnabledRelay.accept(true)
    }

    public func select(item: ChartItem) {
        HapticGenerator.instance.notification(.feedback(.soft))
        pointSelectedItemRelay.accept(factory.selectedPointViewItem(chartItem: item, type: service.chartType, metricsType: service.metricsType, currency: service.currency))
    }

    public func touchUp() {
        pointSelectModeEnabledRelay.accept(false)
    }

}

extension MarketGlobalChartViewModel {

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
