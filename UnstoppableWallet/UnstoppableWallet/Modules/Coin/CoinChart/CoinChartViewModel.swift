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

    //todo: refactor!
    private let pointSelectModeEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let pointSelectedItemRelay = BehaviorRelay<SelectedPointViewItem?>(value: nil)

    private let chartTypeIndexRelay = BehaviorRelay<Int>(value: 0)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let rateRelay = BehaviorRelay<String?>(value: nil)
    private let rateDiffRelay = BehaviorRelay<Decimal?>(value: nil)
    private let chartInfoRelay = BehaviorRelay<CoinChartViewModel.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    let chartTypes = ChartType.allCases.map { $0.title.uppercased() }

    init(service: CoinChartService, factory: CoinChartFactory) {
        self.service = service
        self.factory = factory

        subscribe(disposeBag, service.chartTypeObservable) { [weak self] in self?.sync(chartType: $0) }
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(chartType: service.chartType)
        sync(state: service.state)
    }

    private func sync(chartType: ChartType) {
        chartTypeIndexRelay.accept(ChartType.allCases.firstIndex(of: chartType) ?? 0)
    }

    private func sync(state: DataStatus<CoinChartService.Item>) {
        loadingRelay.accept(state.isLoading)
        errorRelay.accept(state.error?.smartDescription)
        if state.error != nil {
            rateRelay.accept(nil)
            rateDiffRelay.accept(nil)
            chartInfoRelay.accept(nil)

            return
        }

        let rateValue = state.data?.rate.map { CurrencyValue(currency: service.currency, value: $0) }
        rateRelay.accept(rateValue.flatMap { ValueFormatter.instance.format(currencyValue: $0, fractionPolicy: .threshold(high: 1000, low: 0.01), trimmable: false) })
        rateDiffRelay.accept(state.data?.rateDiff24h)

        guard let item = state.data else {
            chartInfoRelay.accept(nil)
            return
        }

        chartInfoRelay.accept(factory.convert(item: item, chartType: service.chartType, currency: service.currency, selectedIndicator: service.selectedIndicator))
    }

}

extension CoinChartViewModel {

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

    var rateDriver: Driver<String?> {
        rateRelay.asDriver()
    }

    var rateDiffDriver: Driver<Decimal?> {
        rateDiffRelay.asDriver()
    }

    var chartInfoDriver: Driver<CoinChartViewModel.ViewItem?> {
        chartInfoRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func onSelectType(at index: Int) {
        let chartTypes = ChartType.allCases
        guard chartTypes.count > index else {
            return
        }

        service.chartType = chartTypes[index]
    }

    func onTap(indicator: ChartIndicatorSet) {
        service.selectedIndicator = service.selectedIndicator.toggle(indicator: indicator)
    }

    func viewDidLoad() {
        service.fetchChartData()
    }

}

extension CoinChartViewModel: IChartViewTouchDelegate {

    public func touchDown() {
        pointSelectModeEnabledRelay.accept(true)
    }

    public func select(item: ChartItem) {
        HapticGenerator.instance.notification(.feedback(.soft))
        pointSelectedItemRelay.accept(factory.selectedPointViewItem(chartItem: item, type: service.chartType, currency: service.currency, macdSelected: service.selectedIndicator.contains(.macd)))
    }

    public func touchUp() {
        pointSelectModeEnabledRelay.accept(false)
    }

}

extension CoinChartViewModel {

    struct ViewItem {
        let chartData: ChartData

        let chartTrend: MovementTrend
        let chartDiff: Decimal?

        let trends: [ChartIndicatorSet: MovementTrend]

        let minValue: String?
        let maxValue: String?

        let timeline: [ChartTimelineItem]

        let selectedIndicator: ChartIndicatorSet?
    }

}

extension ChartType {

    var title: String {
        switch self {
        case .today: return "chart.time_duration.today".localized
        case .day: return "chart.time_duration.day".localized
        case .week: return "chart.time_duration.week".localized
        case .week2: return "chart.time_duration.week2".localized
        case .month: return "chart.time_duration.month".localized
        case .monthByDay: return "chart.time_duration.month".localized
        case .month3: return "chart.time_duration.month3".localized
        case .halfYear: return "chart.time_duration.halyear".localized
        case .year: return "chart.time_duration.year".localized
        case .year2: return "chart.time_duration.year2".localized
        }
    }

}
