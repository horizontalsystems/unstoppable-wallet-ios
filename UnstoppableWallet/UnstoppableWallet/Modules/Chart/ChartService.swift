import UIKit
import RxSwift
import RxCocoa
import XRatesKit
import CoinKit
import CurrencyKit

class ChartService {
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

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

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

        let marketInfo = rateManager.marketInfoObservable(coinType: coinType, currencyCode: currencyKit.baseCurrency.code)
        let chartInfo = rateManager.chartInfoObservable(coinType: coinType, currencyCode: currencyKit.baseCurrency.code, chartType: chartType)

        Observable.zip(marketInfo, chartInfo)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] marketInfo, chartInfo in
                    let item = Item(rate: marketInfo.rate, rateDiff24h: marketInfo.rateDiff, chartInfo: chartInfo)
                    self?.state = .loaded(item: item)
                }, onError: { [weak self] error in
                    self?.state = .error(error)
                })
                .disposed(by: disposeBag)
    }

}

extension ChartService {

    struct Item {
        let rate: Decimal
        let rateDiff24h: Decimal
        let chartInfo: ChartInfo
    }

    enum State {
        case loading
        case loaded(item: Item)
        case error(Error)
    }

}