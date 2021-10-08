import UIKit
import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit

class CoinChartService {
    private var disposeBag = DisposeBag()

    private let marketKit: MarketKit.Kit
    private let chartTypeStorage: IChartTypeStorage
    private let currencyKit: CurrencyKit.Kit
    private let coinUid: String

    private let chartTypeRelay = PublishRelay<ChartType>()
    var chartType: ChartType {
        get {
            chartTypeStorage.chartType ?? .today
        }
        set {
            guard chartTypeStorage.chartType != newValue else {
                return
            }
            chartTypeStorage.chartType = newValue
            chartTypeRelay.accept(newValue)
            fetchChartData()
        }
    }

    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var coinPrice: CoinPrice?
    private var chartInfo: ChartInfo?

    var selectedIndicator = ChartIndicatorSet() {
        didSet {
            syncState()
        }
    }

    init(marketKit: MarketKit.Kit, chartTypeStorage: IChartTypeStorage, currencyKit: CurrencyKit.Kit, coinUid: String) {
        self.marketKit = marketKit
        self.chartTypeStorage = chartTypeStorage
        self.currencyKit = currencyKit
        self.coinUid = coinUid
    }

    func fetchChartData() {
        disposeBag = DisposeBag()
        state = .loading

        coinPrice = marketKit.coinPrice(coinUid: coinUid, currencyCode: currency.code)
        chartInfo = marketKit.chartInfo(coinUid: coinUid, currencyCode: currency.code, chartType: chartType)

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
                .chartInfoObservable(coinUid: coinUid, currencyCode: currency.code, chartType: chartType)
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

    var chartTypeObservable: Observable<ChartType> {
        chartTypeRelay.asObservable()
    }

    var stateObservable: Observable<DataStatus<Item>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
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
