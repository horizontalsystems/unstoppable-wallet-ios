import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class CoinRankService {
    let type: CoinRankModule.RankType
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    var timePeriod: HsTimePeriod = .month1 {
        didSet {
            syncIfPossible(reorder: true)
        }
    }

    private var internalItems: [InternalItem]?

    init(type: CoinRankModule.RankType, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.type = type
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        sync()
    }

    private func valuesSingle() -> Single<[Value]> {
        let currencyCode = currencyKit.baseCurrency.code

        switch type {
        case .cexVolume: return marketKit.cexVolumeRanksSingle(currencyCode: currencyCode).map { $0.map { .multi(value: $0) } }
        case .dexVolume: return marketKit.dexVolumeRanksSingle(currencyCode: currencyCode).map { $0.map { .multi(value: $0) } }
        case .dexLiquidity: return marketKit.dexLiquidityRanksSingle().map { $0.map { .single(value: $0) } }
        case .address: return marketKit.activeAddressRanksSingle().map { $0.map { .multi(value: $0) } }
        case .txCount: return marketKit.transactionCountRanksSingle().map { $0.map { .multi(value: $0) } }
        case .revenue: return marketKit.revenueRanksSingle(currencyCode: currencyCode).map { $0.map { .multi(value: $0) } }
        }
    }

    func sync() {
        disposeBag = DisposeBag()

        state = .loading

        valuesSingle()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] values in
                    self?.handle(values: values)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: disposeBag)
    }

    private func handle(values: [Value]) {
        do {
            let coins = try marketKit.allCoins()

            var coinMap = [String: Coin]()
            coins.forEach { coinMap[$0.uid] = $0 }

            internalItems = values.compactMap { value in
                guard let coin = coinMap[value.coinUid] else {
                    return nil
                }

                return InternalItem(coin: coin, value: value)
            }

            syncIfPossible(reorder: false)
        } catch {
            state = .failed(error: error)
        }
    }

    private func syncIfPossible(reorder: Bool) {
        guard let internalItems else {
            return
        }

        let items = internalItems.compactMap { internalItem -> Item? in
            let resolvedValue: Decimal?

            switch internalItem.value {
            case .multi(let value):
                switch timePeriod {
                case .day1: resolvedValue = value.value1d
                case .week1: resolvedValue = value.value7d
                default: resolvedValue = value.value30d
                }
            case .single(let value):
                resolvedValue = value.value
            }

            guard let resolvedValue else {
                return nil
            }

            return Item(coin: internalItem.coin, value: resolvedValue)
        }

        let sortedItems = items.sorted { $0.value > $1.value }

        state = .loaded(items: sortedItems, reorder: reorder)
    }

}

extension CoinRankService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

}

extension CoinRankService {

    private struct InternalItem {
        let coin: Coin
        let value: Value
    }

    private enum Value {
        case multi(value: RankMultiValue)
        case single(value: RankValue)

        var coinUid: String {
            switch self {
            case .multi(let value): return value.uid
            case .single(let value): return value.uid
            }
        }
    }

    enum State {
        case loading
        case loaded(items: [Item], reorder: Bool)
        case failed(error: Error)
    }

    struct Item {
        let coin: Coin
        let value: Decimal
    }

}
