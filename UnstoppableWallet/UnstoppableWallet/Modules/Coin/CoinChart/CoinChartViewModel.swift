import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import Chart
import CurrencyKit
import HUD

protocol IChartViewModel {
    var chartTitle: String? { get }
    var intervals: [String] { get }
    var intervalsUpdatedWithCurrentIndexDriver: Driver<Int> { get }
    var intervalIndexDriver: Driver<Int> { get }
    var pointSelectModeEnabledDriver: Driver<Bool> { get }
    var pointSelectedItemDriver: Driver<SelectedPointViewItem?> { get }
    var loadingDriver: Driver<Bool> { get }
    var valueDriver: Driver<String?> { get }
    var chartInfoDriver: Driver<CoinChartViewModel.ViewItem?> { get }
    var errorDriver: Driver<String?> { get }

    func onSelectInterval(at index: Int)
    func onTap(indicator: ChartIndicatorSet)
    func start()
    func retry()
}

class CoinChartViewModel {
    private let service: CoinChartService
    private let factory: CoinChartFactory
    private let disposeBag = DisposeBag()

    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "io.horizontalsystems.unstoppable.coin-chart-view-model")

    //todo: refactor!
    private let pointSelectModeEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let pointSelectedItemRelay = BehaviorRelay<SelectedPointViewItem?>(value: nil)

    private let intervalsUpdatedWithCurrentIndex = BehaviorRelay<Int>(value: 0)
    private let intervalIndexRelay = BehaviorRelay<Int>(value: 0)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let valueRelay = BehaviorRelay<String?>(value: nil)
    private let chartInfoRelay = BehaviorRelay<CoinChartViewModel.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

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
        case .byPeriod(let interval): return service.validIntervals.firstIndex(of: interval) ?? 0
        }
    }

    private func sync(periodType: HsPeriodType) {
        intervalIndexRelay.accept(index(periodType: periodType))
    }

    private func sync(state: DataStatus<CoinChartService.Item>) {
        loadingRelay.accept(state.isLoading)
        errorRelay.accept(state.error?.smartDescription)
        if state.error != nil {
            valueRelay.accept(nil)
            chartInfoRelay.accept(nil)

            return
        }

        let rateValue = state.data?.rate.map { CurrencyValue(currency: service.currency, value: $0) }
        valueRelay.accept(rateValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) })

        guard let item = state.data else {
            chartInfoRelay.accept(nil)
            return
        }

        chartInfoRelay.accept(factory.convert(item: item, periodType: service.periodType, currency: service.currency, selectedIndicator: service.selectedIndicator))
    }

}

extension CoinChartViewModel: IChartViewModel {

    var chartTitle: String? {
        nil
    }

    var pointSelectModeEnabledDriver: Driver<Bool> {
        pointSelectModeEnabledRelay.asDriver()
    }

    var pointSelectedItemDriver: Driver<SelectedPointViewItem?> {
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

    var valueDriver: Driver<String?> {
        valueRelay.asDriver()
    }

    var chartInfoDriver: Driver<CoinChartViewModel.ViewItem?> {
        chartInfoRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
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

    func onTap(indicator: ChartIndicatorSet) {
        service.selectedIndicator = service.selectedIndicator.toggle(indicator: indicator)
    }

    func start() {
        service.fetch()
    }

    func retry() {
        service.fetch()
    }

}

extension CoinChartViewModel: IChartViewTouchDelegate {

    public func touchDown() {
        pointSelectModeEnabledRelay.accept(true)
    }

    public func select(item: ChartItem) {
        HapticGenerator.instance.notification(.feedback(.soft))
        pointSelectedItemRelay.accept(factory.selectedPointViewItem(chartItem: item, currency: service.currency, macdSelected: service.selectedIndicator.contains(.macd)))
    }

    public func touchUp() {
        pointSelectModeEnabledRelay.accept(false)
    }

}

extension CoinChartViewModel {

    class ViewItem {
        let chartData: ChartData

        let chartTrend: MovementTrend
        let chartDiff: Decimal?

        let minValue: String?
        let maxValue: String?

        let timeline: [ChartTimelineItem]

        let selectedIndicator: ChartIndicatorSet?

        init(chartData: ChartData, chartTrend: MovementTrend, chartDiff: Decimal?, minValue: String?, maxValue: String?, timeline: [ChartTimelineItem], selectedIndicator: ChartIndicatorSet?) {
            self.chartData = chartData
            self.chartTrend = chartTrend
            self.chartDiff = chartDiff
            self.minValue = minValue
            self.maxValue = maxValue
            self.timeline = timeline
            self.selectedIndicator = selectedIndicator
        }

    }

}

extension HsTimePeriod {

    var title: String {
        switch self {
//        case .today: return "chart.time_duration.today".localized
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
