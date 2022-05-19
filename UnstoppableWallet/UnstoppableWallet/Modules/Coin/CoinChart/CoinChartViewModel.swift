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
    var pointSelectModeEnabledDriver: Driver<Bool> { get }
    var pointSelectedItemDriver: Driver<SelectedPointViewItem?> { get }
    var intervalIndexDriver: Driver<Int> { get }
    var loadingDriver: Driver<Bool> { get }
    var valueDriver: Driver<String?> { get }
    var chartInfoDriver: Driver<CoinChartViewModel.ViewItem?> { get }
    var errorDriver: Driver<String?> { get }

    func onSelectInterval(at index: Int)
    func onTap(indicator: ChartIndicatorSet)
    func viewDidLoad()
    func retry()
}

class CoinChartViewModel {
    private let service: CoinChartService
    private let factory: CoinChartFactory
    private let disposeBag = DisposeBag()

    //todo: refactor!
    private let pointSelectModeEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let pointSelectedItemRelay = BehaviorRelay<SelectedPointViewItem?>(value: nil)

    private let intervalIndexRelay = BehaviorRelay<Int>(value: 0)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let valueRelay = BehaviorRelay<String?>(value: nil)
    private let chartInfoRelay = BehaviorRelay<CoinChartViewModel.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    let intervals = HsTimePeriod.allCases.map { $0.title.uppercased() }

    init(service: CoinChartService, factory: CoinChartFactory) {
        self.service = service
        self.factory = factory

        subscribe(disposeBag, service.intervalObservable) { [weak self] in self?.sync(interval: $0) }
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(interval: service.interval)
        sync(state: service.state)
    }

    private func sync(interval: HsTimePeriod) {
        intervalIndexRelay.accept(HsTimePeriod.allCases.firstIndex(of: interval) ?? 0)
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

        chartInfoRelay.accept(factory.convert(item: item, interval: service.interval, currency: service.currency, selectedIndicator: service.selectedIndicator))
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
        let intervals = HsTimePeriod.allCases
        guard intervals.count > index else {
            return
        }

        service.interval = intervals[index]
    }

    func onTap(indicator: ChartIndicatorSet) {
        service.selectedIndicator = service.selectedIndicator.toggle(indicator: indicator)
    }

    func viewDidLoad() {
        service.fetchChartData()
    }

    func retry() {
        service.fetchChartData()
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
//        case .year2: return "chart.time_duration.year2".localized
        }
    }

}
