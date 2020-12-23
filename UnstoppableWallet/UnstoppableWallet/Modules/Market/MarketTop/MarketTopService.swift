import CurrencyKit
import XRatesKit
import Foundation
import RxSwift
import RxRelay

class MarketTopService {
    private let disposeBag = DisposeBag()
    private var topItemsDisposable: Disposable?

    private let rateManager: IRateManager
    private let currencyKit: ICurrencyKit

    private var fullItems = [TopMarket]()

    private let stateRelay = BehaviorRelay<State>(value: .loading)
    private(set) var marketTopItems = [MarketTopItem]()

    public var period: Period = .period24h {
        didSet {
            syncTopItemsByPeriod()
        }
    }

    init(rateManager: IRateManager, currencyKit: ICurrencyKit) {
        self.rateManager = rateManager
        self.currencyKit = currencyKit

        fetchTopItems()
    }

    private func fetchTopItems() {
        topItemsDisposable?.dispose()
        topItemsDisposable = nil

        stateRelay.accept(.loading)

        topItemsDisposable = rateManager.topMarketInfos(currencyCode: currencyKit.baseCurrency.code)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] in self?.sync(topMarkets: $0) })

        topItemsDisposable?.disposed(by: disposeBag)
    }

    private func syncTopItemsByPeriod() {
        marketTopItems = fullItems.enumerated().map { index, item in
            MarketTopItem(
                    rank: index + 1,
                    coinCode: item.coinCode,
                    coinName: item.coinName,
                    marketCap: item.marketInfo.marketCap,
                    price: item.marketInfo.rate,
                    diff: item.marketInfo.diff,
                    volume: item.marketInfo.volume)
        }

        stateRelay.accept(.loaded)
    }

    private func sync(topMarkets: [TopMarket]) {
        fullItems = topMarkets

        syncTopItemsByPeriod()
    }

}

extension MarketTopService {

    public var currency: Currency {
        currencyKit.baseCurrency
    }

    public var periods: [Period] {
        Period.allCases
    }

    public var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    public func refresh() {
        fetchTopItems()
    }

}

extension MarketTopService {

    struct MarketTopItem {
        let rank: Int
        let coinCode: String
        let coinName: String
        let marketCap: Decimal
        let price: Decimal
        let diff: Decimal
        let volume: Decimal
    }

    enum Period: Int, CaseIterable {
        case period24h
        case periodWeek
        case periodMonth
    }

    enum State {
        case loaded
        case loading
        case error(error: Error)
    }

}
