import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewGlobalService {
    private let listCount = 5

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private var internalStatus: DataStatus<[GlobalMarketPoint]> = .loading {
        didSet {
            syncState()
        }
    }

    private let statusRelay = BehaviorRelay<DataStatus<GlobalMarketData>>(value: .loading)

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, appManager: IAppManager) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] _ in
            self?.syncInternalState()
        }
        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in
            self?.syncInternalState()
        }

        syncInternalState()
    }

    private func syncInternalState() {
        syncDisposeBag = DisposeBag()

        if case .failed = statusRelay.value {
            internalStatus = .loading
        }

        marketKit.globalMarketPointsSingle(currencyCode: currency.code, timePeriod: .day1)
                .subscribe(onSuccess: { [weak self] globalMarketPoints in
                    self?.internalStatus = .completed(globalMarketPoints)
                }, onError: { [weak self] error in
                    self?.internalStatus = .failed(error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func syncState() {
        statusRelay.accept(internalStatus.map { internalState in
            globalMarketData(globalMarketPoints: internalState)
        })
    }

    private func globalMarketData(globalMarketPoints: [GlobalMarketPoint]) -> GlobalMarketData {
        let marketCapPointItems = globalMarketPoints.map {
            GlobalMarketPointItem(timestamp: $0.timestamp, amount: $0.marketCap)
        }
        let volume24hPointItems = globalMarketPoints.map {
            GlobalMarketPointItem(timestamp: $0.timestamp, amount: $0.volume24h)
        }
        let defiMarketCapPointItems = globalMarketPoints.map {
            GlobalMarketPointItem(timestamp: $0.timestamp, amount: $0.defiMarketCap)
        }
        let tvlPointItems = globalMarketPoints.map {
            GlobalMarketPointItem(timestamp: $0.timestamp, amount: $0.tvl)
        }

        return GlobalMarketData(
                marketCap: globalMarketItem(pointItems: marketCapPointItems),
                volume24h: globalMarketItem(pointItems: volume24hPointItems),
                defiMarketCap: globalMarketItem(pointItems: defiMarketCapPointItems),
                defiTvl: globalMarketItem(pointItems: tvlPointItems)
        )
    }

    private func globalMarketItem(pointItems: [GlobalMarketPointItem]) -> GlobalMarketItem {
        GlobalMarketItem(
                amount: amount(pointItems: pointItems),
                diff: diff(pointItems: pointItems),
                pointItems: pointItems
        )
    }

    private func amount(pointItems: [GlobalMarketPointItem]) -> CurrencyValue? {
        guard let lastAmount = pointItems.last?.amount else {
            return nil
        }

        return CurrencyValue(currency: currency, value: lastAmount)
    }

    private func diff(pointItems: [GlobalMarketPointItem]) -> Decimal? {
        guard let firstAmount = pointItems.first?.amount, let lastAmount = pointItems.last?.amount, firstAmount != 0 else {
            return nil
        }

        return (lastAmount - firstAmount) * 100 / firstAmount
    }

    private func syncIfPossible() {
        guard case .completed = internalStatus else {
            return
        }

        syncState()
    }

}

extension MarketOverviewGlobalService {

    var stateObservable: Observable<DataStatus<GlobalMarketData>> {
        statusRelay.asObservable()
    }

    func refresh() {
        syncInternalState()
    }

}

extension MarketOverviewGlobalService: IMarketListDecoratorService {

    var initialMarketFieldIndex: Int {
        0
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(marketFieldIndex: Int) {
        if case .completed = statusRelay.value {
            statusRelay.accept(statusRelay.value)
        }
    }

}

extension MarketOverviewGlobalService {

    struct GlobalMarketData {
        let marketCap: GlobalMarketItem
        let volume24h: GlobalMarketItem
        let defiMarketCap: GlobalMarketItem
        let defiTvl: GlobalMarketItem
    }

    struct GlobalMarketItem {
        let amount: CurrencyValue?
        let diff: Decimal?
        let pointItems: [GlobalMarketPointItem]
    }

    struct GlobalMarketPointItem {
        let timestamp: TimeInterval
        let amount: Decimal
    }

}
