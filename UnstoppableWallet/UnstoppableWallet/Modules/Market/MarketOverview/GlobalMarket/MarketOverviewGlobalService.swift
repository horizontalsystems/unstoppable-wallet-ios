import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewGlobalService {
    private let baseService: MarketOverviewService
    private let disposeBag = DisposeBag()

    private let globalMarketDataRelay = PublishRelay<GlobalMarketData?>()
    private(set) var globalMarketData: GlobalMarketData? {
        didSet {
            globalMarketDataRelay.accept(globalMarketData)
        }
    }

    init(baseService: MarketOverviewService) {
        self.baseService = baseService

        subscribe(disposeBag, baseService.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync()
    }

    private func sync(state: DataStatus<MarketOverviewService.Item>? = nil) {
        let state = state ?? baseService.state

        globalMarketData = state.data.map { item in
            globalMarketData(globalMarketPoints: item.marketOverview.globalMarketPoints)
        }
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

}

extension MarketOverviewGlobalService {

    var globalMarketDataObservable: Observable<GlobalMarketData?> {
        globalMarketDataRelay.asObservable()
    }

    var currency: Currency {
        baseService.currency
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
