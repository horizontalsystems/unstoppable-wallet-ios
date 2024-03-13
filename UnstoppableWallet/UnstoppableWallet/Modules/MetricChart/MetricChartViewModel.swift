import Chart
import Combine
import Foundation
import HUD
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class MetricChartViewModel {
    private let service: MetricChartService
    private let factory: MetricChartFactory
    private var cancellables = Set<AnyCancellable>()

    private let pointSelectedItemRelay = BehaviorRelay<ChartModule.SelectedPointViewItem?>(value: nil)

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let chartInfoRelay = BehaviorRelay<ChartModule.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<Bool>(value: false)
    private let needUpdateIntervalsRelay = BehaviorRelay<Int>(value: 0)

    init(service: MetricChartService, factory: MetricChartFactory) {
        self.service = service
        self.factory = factory

        service.$interval
            .sink { [weak self] in self?.sync(interval: $0) }
            .store(in: &cancellables)

        service.$state
            .sink { [weak self] in self?.sync(state: $0) }
            .store(in: &cancellables)

        service.$intervals
            .sink { [weak self] _ in self?.updateIntervals() }
            .store(in: &cancellables)

        sync(interval: service.interval)
        sync(state: service.state)
    }

    private func sync(interval _: HsPeriodType) {
//        intervalIndexRelay.accept(service.intervals.firstIndex(of: interval) ?? 0)
        let index = service.intervals.firstIndex(of: service.interval) ?? 0
        needUpdateIntervalsRelay.accept(index)
    }

    private func updateIntervals() {
        let index = service.intervals.firstIndex(of: service.interval) ?? 0
        needUpdateIntervalsRelay.accept(index)
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
        case let .completed(itemData):
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
    var showAll: Bool { service.intervals.contains(where: \.byStartTime) }

    var pointSelectedItemDriver: Driver<ChartModule.SelectedPointViewItem?> {
        pointSelectedItemRelay.asDriver()
    }

    var intervalsUpdatedWithCurrentIndexDriver: Driver<Int> {
        needUpdateIntervalsRelay.asDriver()
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

    var intervals: [String] { service.intervals.timePeriods.map { $0.title.uppercased() } }

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
    public func touchDown() {}

    public func select(item: ChartItem, indicators _: [ChartIndicator]) {
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
