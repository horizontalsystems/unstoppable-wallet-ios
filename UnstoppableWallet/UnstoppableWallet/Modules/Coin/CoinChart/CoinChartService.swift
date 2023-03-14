import UIKit
import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit

class CoinChartService {
    private var disposeBag = DisposeBag()

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let coinUid: String

    private let periodTypeRelay = PublishRelay<HsPeriodType>()
    var periodType: HsPeriodType = .day1 {
        didSet {
            if periodType != oldValue {
                periodTypeRelay.accept(periodType)
                fetch()
            }
        }
    }

    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
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
    private var chartInfo: ChartInfo?

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, coinUid: String) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.coinUid = coinUid
    }

    func fetch() {
        let genesisTimeSingle: Single<TimeInterval>

        if let startTime {
            genesisTimeSingle = .just(startTime)
        } else {
            genesisTimeSingle = marketKit.chartPriceStart(coinUid: coinUid)
        }

        disposeBag = DisposeBag()

        genesisTimeSingle
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] startTime in
                    self?.startTime = startTime
                    self?.fetchChartData()
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    private func fetchChartData() {
        disposeBag = DisposeBag()
        state = .loading

        coinPrice = marketKit.coinPrice(coinUid: coinUid, currencyCode: currency.code)
        chartInfo = marketKit.chartInfo(coinUid: coinUid, currencyCode: currency.code, periodType: periodType)

        marketKit
                .coinPriceObservable(coinUid: coinUid, currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coinPrice in
                    self?.coinPrice = coinPrice
                    self?.syncState()
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)

        marketKit
                .chartInfoObservable(coinUid: coinUid, currencyCode: currency.code, periodType: periodType)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] chartInfo in
                    self?.chartInfo = chartInfo
                    self?.syncState()
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)

        syncState()
    }

    private func syncState() {
        guard let chartInfo = chartInfo, let coinPrice = coinPrice else {
            return
        }

        let item = Item(
                coinUid: coinUid,
                rate: coinPrice.value,
                rateDiff24h: coinPrice.diff,
                timestamp: coinPrice.timestamp,
                chartInfo: chartInfo
        )

        state = .completed(item)
    }

}

extension CoinChartService {

    var periodTypeObservable: Observable<HsPeriodType> {
        periodTypeRelay.asObservable()
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

    func setPeriod(interval: HsTimePeriod) {
        periodType = .byPeriod(interval)
    }

}

extension CoinChartService {

    struct Item {
        let coinUid: String
        let rate: Decimal?
        let rateDiff24h: Decimal?
        let timestamp: TimeInterval?
        let chartInfo: ChartInfo
    }

}
