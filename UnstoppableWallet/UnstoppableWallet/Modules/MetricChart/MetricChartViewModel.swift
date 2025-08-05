import Chart
import Combine
import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

class MetricChartViewModel: ObservableObject {
    private let service: MetricChartService
    private let factory: IMetricChartFactory
    private var cancellables = Set<AnyCancellable>()

    private let pointSelectedItemRelay = BehaviorRelay<ChartModule.SelectedPointViewItem?>(value: nil)

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let chartInfoRelay = BehaviorRelay<ChartModule.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<Bool>(value: false)
    private let needUpdateIntervalsRelay = BehaviorRelay<Int>(value: 0)

    @Published var periodType: HsPeriodType

    init(service: MetricChartService, factory: IMetricChartFactory) {
        self.service = service
        self.factory = factory
        periodType = service.interval

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

    var intervals: [String] { service.intervals.timePeriods.map { $0.shortTitle.uppercased() } }

    func onSelectInterval(at index: Int) {
        let chartTypes = service.intervals
        guard chartTypes.count > index else {
            return
        }
        let interval = chartTypes[index]
        service.interval = interval
        periodType = interval
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

extension MetricChartViewModel {
    static func instance(type: MarketGlobalModule.MetricsType) -> MetricChartViewModel {
        let fetcher = MarketGlobalFetcher(currencyManager: Core.shared.currencyManager, marketKit: Core.shared.marketKit, metricsType: type)
        let service = MetricChartService(
            chartFetcher: fetcher,
            interval: .byPeriod(.day1),
            statPage: type.statPage
        )

        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        return MetricChartViewModel(service: service, factory: factory)
    }

    static func etfInstance(category: MarketEtfFetcher.EtfCategory) -> MetricChartViewModel {
        let fetcher = MarketEtfFetcher(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager, category: category)
        let service = MetricChartService(
            chartFetcher: fetcher,
            interval: .byPeriod(.day1),
            statPage: StatPage.globalMetricsEtf
        )

        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        return MetricChartViewModel(service: service, factory: factory)
    }

    static func platformInstance(platform: TopPlatform) -> MetricChartViewModel {
        let marketCapFetcher = TopPlatformMarketCapFetcher(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager, topPlatform: platform)
        let chartService = MetricChartService(chartFetcher: marketCapFetcher, interval: .byPeriod(.week1), statPage: .topPlatform)
        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale, hardcodedRightMode: "top_platform.total_cap".localized)
        return MetricChartViewModel(service: chartService, factory: factory)
    }

    static func sectorInstance(sector: CoinCategory) -> MetricChartViewModel {
        let marketCapFetcher = SectorMarketCapFetcher(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager, sector: sector)
        let chartService = MetricChartService(chartFetcher: marketCapFetcher, interval: .byPeriod(.day1), statPage: .sector)
        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale, hardcodedRightMode: "top_platform.total_cap".localized)
        return MetricChartViewModel(service: chartService, factory: factory)
    }

    static func vaultInstance(vault: Vault) -> MetricChartViewModel {
        let marketCapFetcher = VaultChartFetcher(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager, vault: vault)
        let chartService = MetricChartService(chartFetcher: marketCapFetcher, interval: .byPeriod(.week1), statPage: .vault)
        let factory = MarketVaultChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        return MetricChartViewModel(service: chartService, factory: factory)
    }

    static func instance(coin: Coin, type: CoinProChartModule.ProChartType) -> MetricChartViewModel {
        let chartFetcher = ProChartFetcher(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager, coin: coin, type: type)

        let chartService = MetricChartService(
            chartFetcher: chartFetcher,
            interval: .byPeriod(.month1),
            statPage: type.statPage
        )

        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        return MetricChartViewModel(service: chartService, factory: factory)
    }
}
