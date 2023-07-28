import Foundation
import Combine
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import Chart
import CurrencyKit
import HUD

class MetricChartViewModel {
    private let service: MetricChartService
    private let factory: MetricChartFactory
    private var cancellables = Set<AnyCancellable>()

    private let pointSelectedItemRelay = BehaviorRelay<ChartModule.SelectedPointViewItem?>(value: nil)

    private let intervalIndexRelay = BehaviorRelay<Int>(value: 0)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let chartInfoRelay = BehaviorRelay<ChartModule.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<Bool>(value: false)

    init(service: MetricChartService, factory: MetricChartFactory) {
        self.service = service
        self.factory = factory

        service.$interval
                .sink { [weak self] in self?.sync(interval: $0) }
                .store(in: &cancellables)

        service.$state
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

        sync(interval: service.interval)
        sync(state: service.state)
    }

    private func sync(interval: HsTimePeriod) {
        intervalIndexRelay.accept(service.intervals.firstIndex(of: interval) ?? 0)
    }

    private func sync(state: DataStatus<MetricChartModule.ItemData>) {
        switch state {
        case .loading:
            loadingRelay.accept(true)
            errorRelay.accept(false)
        case .failed:
            loadingRelay.accept(false)
            errorRelay.accept(true)
            chartInfoRelay.accept(nil)
        case .completed(let itemData):
            loadingRelay.accept(false)

            if let viewItem = factory.convert(itemData: itemData, valueType: service.valueType) {
                errorRelay.accept(false)
                chartInfoRelay.accept(viewItem)
            } else {
                errorRelay.accept(true)
                chartInfoRelay.accept(nil)
            }
        }
    }

}

extension MetricChartViewModel: IChartViewModel {

    var pointSelectedItemDriver: Driver<ChartModule.SelectedPointViewItem?> {
        pointSelectedItemRelay.asDriver()
    }

    var intervalsUpdatedWithCurrentIndexDriver: Driver<Int> {
        .empty()
    }

    var intervalIndexDriver: Driver<Int> {
        intervalIndexRelay.asDriver()
    }

    var indicatorsShownDriver: Driver<Bool> {
        .just(true)
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var chartInfoDriver: Driver<ChartModule.ViewItem?> {
        chartInfoRelay.asDriver()
    }

    var errorDriver: Driver<Bool> {
        errorRelay.asDriver()
    }

    var intervals: [String] { service.intervals.map { $0.title.uppercased() } }

    func onSelectInterval(at index: Int) {
        let chartTypes = service.intervals
        guard chartTypes.count > index else {
            return
        }

        service.interval = chartTypes[index]
    }

    func start() {
        service.fetchChartData()
    }

    func retry() {
        service.fetchChartData()
    }

}

extension MetricChartViewModel: IChartViewTouchDelegate {

    public func touchDown() {
    }

    public func select(item: ChartItem, indicators: [ChartIndicator]) {
        HapticGenerator.instance.notification(.feedback(.soft))

        pointSelectedItemRelay.accept(
                factory.selectedPointViewItem(
                        chartItem: item,
                        firstChartItem: chartInfoRelay.value?.chartData.items.first,
                        valueType: service.valueType
                )
        )
    }

    public func touchUp() {
        pointSelectedItemRelay.accept(nil)
    }

}
