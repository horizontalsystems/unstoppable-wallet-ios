import UIKit
import RxSwift
import RxCocoa
import XRatesKit
import CoinKit
import CurrencyKit

class CoinChartService {
    private var disposeBag = DisposeBag()

    private let rateManager: IRateManager
    private let chartTypeStorage: IChartTypeStorage
    private let currencyKit: CurrencyKit.Kit
    private let coinType: CoinType

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

    private var latestRate: LatestRate?
    private var chartInfo: ChartInfo?

    var selectedIndicator = ChartIndicatorSet() {
        didSet {
            syncState()
        }
    }

    init(rateManager: IRateManager, chartTypeStorage: IChartTypeStorage, currencyKit: CurrencyKit.Kit, coinType: CoinType) {
        self.rateManager = rateManager
        self.chartTypeStorage = chartTypeStorage
        self.currencyKit = currencyKit
        self.coinType = coinType

        fetchChartData()
    }

    private func fetchChartData() {
        disposeBag = DisposeBag()
        state = .loading

        latestRate = rateManager.latestRate(coinType: coinType, currencyCode: currency.code)
        chartInfo = rateManager.chartInfo(coinType: coinType, currencyCode: currency.code, chartType: chartType)

        rateManager
                .latestRateObservable(coinType: coinType, currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] latestRate in
                    self?.latestRate = latestRate
                    self?.syncState()
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)

        rateManager
                .chartInfoObservable(coinType: coinType, currencyCode: currency.code, chartType: chartType)
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
        guard let chartInfo = chartInfo, let latestRate = latestRate else {
            return
        }

        let item = Item(
                rate: latestRate.rate,
                rateDiff24h: latestRate.rateDiff24h,
                timestamp: latestRate.timestamp,
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
        let rate: Decimal?
        let rateDiff24h: Decimal?
        let timestamp: TimeInterval?
        let chartInfo: ChartInfo
    }

}
