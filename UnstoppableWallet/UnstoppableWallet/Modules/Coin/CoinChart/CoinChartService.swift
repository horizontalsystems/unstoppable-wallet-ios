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
    private let currencyKit: ICurrencyKit
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

    var selectedIndicator = ChartIndicatorSet()

    init(rateManager: IRateManager, chartTypeStorage: IChartTypeStorage, currencyKit: ICurrencyKit, coinType: CoinType) {
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

        let latestRateObservable = rateManager.latestRateObservable(coinType: coinType, currencyCode: currency.code).delay(.seconds(3), scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
        let chartInfoObservable = rateManager.chartInfoObservable(coinType: coinType, currencyCode: currency.code, chartType: chartType).delay(.seconds(5), scheduler: ConcurrentDispatchQueueScheduler(qos: .background))

        latestRateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] latestRate in
                    print("LATEST RATE COME!")
                    self?.latestRate = latestRate
                    self?.syncState()
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)

        chartInfoObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] chartInfo in
                    print("CHART INFO COME!")
                    self?.chartInfo = chartInfo
                    self?.syncState()
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)

        syncState()
    }

    private func syncState() {
        guard let chartInfo = chartInfo else {
            print("chartInfo is nil")
            return
        }

        print("coming rate: \(latestRate?.rate)")
        print("coming points: \(chartInfo.points.count)")
        let item = Item(
                rate: latestRate?.rate,
                rateDiff24h: latestRate?.rateDiff24h,
                timestamp: latestRate?.timestamp,
                chartInfo: chartInfo
        )

        state = .completed(item)
    }

    deinit {
        print("\(self)")
    }

}

extension CoinChartService {

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
