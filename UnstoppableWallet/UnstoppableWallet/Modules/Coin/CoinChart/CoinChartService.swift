import Combine
import UIKit
import RxSwift
import RxCocoa
import Chart
import MarketKit
import CurrencyKit
import HsExtensions

protocol IChartPointFetcher {
    var points: DataStatus<[ChartPoint]> { get }
    var pointsUpdatedPublisher: AnyPublisher<Void, Never> { get }
}

class CoinChartService {
    private var tasks = Set<AnyTask>()
    private var cancellables = Set<AnyCancellable>()

    private let marketKit: MarketKit.Kit
    private let localStorage: LocalStorage
    private let currencyKit: CurrencyKit.Kit
    private let indicatorRepository: IChartIndicatorsRepository
    private let coinUid: String

    private let indicatorsShownUpdatedRelay = PublishRelay<()>()
    var indicatorsShown: Bool {
        get {
            localStorage.indicatorsShown
        }
        set {
            localStorage.indicatorsShown = newValue
            indicatorsShownUpdatedRelay.accept(())
        }
    }

    private let periodTypeRelay = PublishRelay<HsPeriodType>()
    var periodType: HsPeriodType {
        didSet {
            if periodType != oldValue {
                periodTypeRelay.accept(periodType)
                fetch()
            }
        }
    }

    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private let stateUpdatedSubject = PassthroughSubject<Void, Never>()

    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
            stateUpdatedSubject.send()
        }
    }

    private let intervalsUpdatedRelay = PublishRelay<()>()
    private(set) var startTime: TimeInterval? {
        didSet {
            if startTime != oldValue {
                intervalsUpdatedRelay.accept(())
            }
        }
    }

    private var coinPrice: CoinPrice?
    private var chartPointsMap = [HsPeriodType: ChartPointsItem]()

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, localStorage: LocalStorage, indicatorRepository: IChartIndicatorsRepository, coinUid: String) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.localStorage = localStorage
        self.indicatorRepository = indicatorRepository
        self.coinUid = coinUid

        periodType = .byCustomPoints(.day1, indicatorRepository.extendedPointCount)
        indicatorRepository.updatedPublisher
                .sink { [weak self] in
                    self?.fetchWithUpdatedIndicators()
                }
                .store(in: &cancellables)
    }

    private func fetchStartTime() {
        Task { [weak self, marketKit, coinUid] in
            do {
                self?.startTime = try await marketKit.chartPriceStart(coinUid: coinUid)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

    private func fetchChartInfo() {
        Task { [weak self, marketKit, coinUid, currency, periodType] in
            do {
                let (fromTimestamp, chartPoints) = try await marketKit.chartPoints(coinUid: coinUid, currencyCode: currency.code, periodType: periodType)
                self?.handle(fromTimestamp: fromTimestamp, chartPoints: chartPoints, periodType: periodType)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

    private func handle(fromTimestamp: TimeInterval, chartPoints: [ChartPoint], periodType: HsPeriodType) {
        guard chartPoints.count >= 2, let firstPoint = chartPoints.first(where: { $0.timestamp >= fromTimestamp}), let lastPoint = chartPoints.last else {
            state = .failed(ChartError.notEnoughPoints)
            return
        }

        chartPointsMap[periodType] = ChartPointsItem(points: chartPoints, firstPoint: firstPoint, lastPoint: lastPoint)
        syncState()
    }

    private func syncState() {
        guard let chartPointsItem = chartPointsMap[periodType], let coinPrice else {
            return
        }

        let item = Item(
                coinUid: coinUid,
                rate: coinPrice.value,
                rateDiff24h: coinPrice.diff,
                timestamp: coinPrice.timestamp,
                chartPointsItem: chartPointsItem,
                indicators: indicatorRepository.indicators
        )

        state = .completed(item)
    }

}

extension CoinChartService {

    var periodTypeObservable: Observable<HsPeriodType> {
        periodTypeRelay.asObservable()
    }

    var indicatorsShownUpdatedObservable: Observable<()> {
        indicatorsShownUpdatedRelay.asObservable()
    }

    var intervalsUpdatedObservable: Observable<()> {
        intervalsUpdatedRelay.asObservable()
    }

    var stateObservable: Observable<DataStatus<Item>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var validIntervals: [HsTimePeriod] {
        HsChartHelper.validIntervals(startTime: startTime)
    }

    func setPeriodAll() {
        periodType = .byStartTime(startTime ?? 0)
    }

    func fetchWithUpdatedIndicators() {
        switch periodType {
        case .byCustomPoints(let interval, _):
            let updatedType: HsPeriodType = .byCustomPoints(interval, indicatorRepository.extendedPointCount)
            if periodType == updatedType {
                fetch()
            } else {
                periodType = updatedType
            }
        default: ()
        }
    }

    func setPeriod(interval: HsTimePeriod) {
        periodType = .byCustomPoints(interval, indicatorRepository.extendedPointCount)
    }

    func start() {
        coinPrice = marketKit.coinPrice(coinUid: coinUid, currencyCode: currency.code)

        marketKit.coinPricePublisher(tag: "coin-chart-service", coinUid: coinUid, currencyCode: currency.code)
                .sink { [weak self] coinPrice in
                    self?.coinPrice = coinPrice
                    self?.syncState()
                }
                .store(in: &cancellables)

        fetch()
    }

    func fetch() {
        tasks = Set()
        state = .loading

        if startTime == nil {
            fetchStartTime()
        }

        if chartPointsMap[periodType] != nil {
            syncState()
        } else {
            fetchChartInfo()
        }
    }

}

extension CoinChartService: IChartPointFetcher {

    var points: DataStatus<[ChartPoint]> {
        state.map { item in item.chartPointsItem.points }
    }

    var pointsUpdatedPublisher: AnyPublisher<(), Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }

}

extension CoinChartService {

    struct Item {
        let coinUid: String
        let rate: Decimal
        let rateDiff24h: Decimal?
        let timestamp: TimeInterval
        let chartPointsItem: ChartPointsItem
        let indicators: [ChartIndicator]
    }

    struct ChartPointsItem {
        let points: [ChartPoint]
        let firstPoint: ChartPoint
        let lastPoint: ChartPoint
    }

    enum ChartError: Error {
        case notEnoughPoints
    }

}
