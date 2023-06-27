import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import Chart
import CurrencyKit
import HUD

class CoinChartViewModel {
    private let service: CoinChartService
    private let factory: CoinChartFactory
    private let disposeBag = DisposeBag()

    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "io.horizontalsystems.unstoppable.coin-chart-view-model")

    private let pointSelectedItemRelay = BehaviorRelay<ChartModule.SelectedPointViewItem?>(value: nil)

    private let intervalsUpdatedWithCurrentIndex = BehaviorRelay<Int>(value: 0)
    private let intervalIndexRelay = BehaviorRelay<Int>(value: 0)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let chartInfoRelay = BehaviorRelay<ChartModule.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<Bool>(value: false)
    private let openSettingsRelay = PublishRelay<()>()

    var intervals: [String] {
        service.validIntervals.map { $0.title } + ["chart.time_duration.all".localized]
    }

    init(service: CoinChartService, factory: CoinChartFactory) {
        self.service = service
        self.factory = factory

        subscribe(scheduler, disposeBag, service.intervalsUpdatedObservable) { [weak self] in self?.syncIntervalsUpdate() }
        subscribe(scheduler, disposeBag, service.periodTypeObservable) { [weak self] in self?.sync(periodType: $0) }
        subscribe(scheduler, disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(periodType: service.periodType)
        sync(state: service.state)
    }

    private func syncIntervalsUpdate() {
        intervalsUpdatedWithCurrentIndex.accept(index(periodType: service.periodType))
    }

    private func index(periodType: HsPeriodType) -> Int {
        switch periodType {
        case .byStartTime: return service.validIntervals.count
        case .byPeriod(let interval), .byCustomPoints(let interval, _): return service.validIntervals.firstIndex(of: interval) ?? 0
        }
    }

    private func sync(periodType: HsPeriodType) {
        intervalIndexRelay.accept(index(periodType: periodType))
    }

    private func sync(state: DataStatus<CoinChartService.Item>) {
        switch state {
        case .loading:
            loadingRelay.accept(true)
            errorRelay.accept(false)
        case .failed:
            loadingRelay.accept(false)
            errorRelay.accept(true)
            chartInfoRelay.accept(nil)
        case .completed(let item):
            loadingRelay.accept(false)
            errorRelay.accept(false)
            let convert = factory.convert(item: item, periodType: service.periodType, currency: service.currency)
            print("CoinChartViewModel: \(convert.indicators.first?.json)")
            chartInfoRelay.accept(convert)
        }
    }

}

extension CoinChartViewModel: IChartViewModel {

    var pointSelectedItemDriver: Driver<ChartModule.SelectedPointViewItem?> {
        pointSelectedItemRelay.asDriver()
    }

    var intervalsUpdatedWithCurrentIndexDriver: Driver<Int> {
        intervalsUpdatedWithCurrentIndex.asDriver()
    }

    var intervalIndexDriver: Driver<Int> {
        intervalIndexRelay.asDriver()
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

    var openSettingsSignal: Signal<()> {
        openSettingsRelay.asSignal()
    }

    func onSelectInterval(at index: Int) {
        let intervals = service.validIntervals

        if intervals.count == index {
            service.setPeriodAll()
            return
        }

        guard intervals.count > index else {
            return
        }

        service.setPeriod(interval: intervals[index])
    }

    func start() {
        service.start()
    }

    func retry() {
        service.fetch()
    }

    func onTapChartSettings() {
        // check subscriptions
        openSettingsRelay.accept(())
    }

    func toggleIndicators() {
    }

}

extension CoinChartViewModel: IChartViewTouchDelegate {

    public func touchDown() {
    }

    public func select(item: ChartItem) {
        HapticGenerator.instance.notification(.feedback(.soft))

        pointSelectedItemRelay.accept(
                factory.selectedPointViewItem(
                        chartItem: item,
                        firstChartItem: chartInfoRelay.value?.chartData.visibleItems.first,
                        currency: service.currency
                )
        )
    }

    public func touchUp() {
        pointSelectedItemRelay.accept(nil)
    }

}

extension HsTimePeriod {

    var title: String {
        switch self {
        case .day1: return "chart.time_duration.day".localized
        case .week1: return "chart.time_duration.week".localized
        case .week2: return "chart.time_duration.week2".localized
        case .month1: return "chart.time_duration.month".localized
        case .month3: return "chart.time_duration.month3".localized
        case .month6: return "chart.time_duration.halfyear".localized
        case .year1: return "chart.time_duration.year".localized
        case .year2: return "chart.time_duration.year2".localized
        }
    }

}
