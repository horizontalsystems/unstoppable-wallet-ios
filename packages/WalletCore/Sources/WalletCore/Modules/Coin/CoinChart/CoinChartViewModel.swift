import Chart
import Combine
import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class CoinChartViewModel: ObservableObject {
    let service: CoinChartService
    private let factory: CoinChartFactory
    private let disposeBag = DisposeBag()

    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "\(AppConfig.label).coin-chart-view-model")

    private let pointSelectedItemRelay = BehaviorRelay<ChartModule.SelectedPointViewItem?>(value: nil)

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let chartInfoRelay = BehaviorRelay<ChartModule.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<Bool>(value: false)
    private let indicatorsShownRelay = BehaviorRelay<Bool>(value: true)
    private let openSettingsRelay = PublishRelay<Void>()

    @Published private(set) var indicatorsShown: Bool
    @Published private(set) var intervalTitles: [String] = []
    @Published private(set) var selectedIntervalIndex: Int = 0

    init(service: CoinChartService, factory: CoinChartFactory) {
        self.service = service
        self.factory = factory

        indicatorsShown = service.indicatorsShown

        subscribe(scheduler, disposeBag, service.intervalsUpdatedObservable) { [weak self] in self?.syncIntervals() }
        subscribe(scheduler, disposeBag, service.periodTypeObservable) { [weak self] _ in self?.syncIntervals() }
        subscribe(scheduler, disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(scheduler, disposeBag, service.indicatorsShownUpdatedObservable) { [weak self] in self?.updateIndicatorsShown() }

        let initialState = intervalState(periodType: service.periodType)
        intervalTitles = initialState.titles
        selectedIntervalIndex = initialState.selectedIndex

        sync(state: service.state)
        indicatorsShownRelay.accept(service.indicatorsShown)
    }

    private func updateIndicatorsShown() {
        indicatorsShownRelay.accept(service.indicatorsShown)
        indicatorsShown = service.indicatorsShown
    }

    private func index(periodType: HsPeriodType) -> Int {
        switch periodType {
        case .byStartTime: return service.validIntervals.count
        case let .byPeriod(interval), let .byCustomPoints(interval, _): return service.validIntervals.firstIndex(of: interval) ?? 0
        }
    }

    private func intervalState(periodType: HsPeriodType) -> (titles: [String], selectedIndex: Int) {
        var titles = service.validIntervals.map(\.shortTitle)

        if !titles.isEmpty {
            titles.append("chart.time_duration.all".localized)
        }

        return (titles, index(periodType: periodType))
    }

    private func syncIntervals() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let state = intervalState(periodType: service.periodType)
            intervalTitles = state.titles
            selectedIntervalIndex = state.selectedIndex
        }
    }

    func onSelectInterval(at index: Int) {
        let intervals = service.validIntervals

        guard index >= 0, index <= intervals.count else {
            return
        }

        selectedIntervalIndex = index

        if index == intervals.count {
            service.setPeriodAll()
            return
        }

        service.setPeriod(interval: intervals[index])
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
        case let .completed(item):
            loadingRelay.accept(false)
            errorRelay.accept(false)
            let convert = factory.convert(item: item, periodType: service.periodType, currency: service.currency)
            chartInfoRelay.accept(convert)
        }
    }
}

extension CoinChartViewModel: IChartViewModel {
    var pointSelectedItemDriver: Driver<ChartModule.SelectedPointViewItem?> {
        pointSelectedItemRelay.asDriver()
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

    var indicatorsShownDriver: Driver<Bool> {
        indicatorsShownRelay.asDriver()
    }

    var openSettingsSignal: Signal<Void> {
        openSettingsRelay.asSignal()
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

    func onToggleIndicators() {
        service.indicatorsShown.toggle()
    }
}

extension CoinChartViewModel: IChartViewTouchDelegate {
    func touchDown() {}

    func select(item: ChartItem, indicators: [ChartIndicator]) {
        HapticGenerator.instance.notification(.feedback(.soft))

        pointSelectedItemRelay.accept(
            factory.selectedPointViewItem(
                chartItem: item,
                indicators: indicators,
                firstChartItem: chartInfoRelay.value?.chartData.visibleItems.first,
                currency: service.currency
            )
        )
    }

    func touchUp() {
        pointSelectedItemRelay.accept(nil)
    }
}

extension CoinChartViewModel {
    static func instance(coinUid: String) -> CoinChartViewModel {
        let repository = ChartIndicatorsRepository(localStorage: Core.shared.localStorage)
        let chartService = CoinChartService(
            marketKit: Core.shared.marketKit,
            currencyManager: Core.shared.currencyManager,
            localStorage: Core.shared.localStorage,
            indicatorRepository: repository,
            coinUid: coinUid
        )
        let chartFactory = CoinChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        return CoinChartViewModel(service: chartService, factory: chartFactory)
    }
}

extension [HsTimePeriod] {
    var periodTypes: [HsPeriodType] {
        map { .byPeriod($0) }
    }
}

extension [HsPeriodType] {
    var timePeriods: [HsTimePeriod] {
        compactMap {
            if case let .byPeriod(interval) = $0 {
                return interval
            }
            return nil
        }
    }
}
