import Foundation
import MarketKit
import CurrencyKit
import HsExtensions

class CoinRankService {
    let type: CoinRankModule.RankType
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: State = .loading

    var sortDirectionAscending: Bool = false {
        didSet {
            syncIfPossible(reorder: true)
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

    func sync() {
        tasks = Set()

        state = .loading

        Task { [weak self, marketKit, currencyKit, type] in
            do {
                let currencyCode = currencyKit.baseCurrency.code
                let values: [Value]

                switch type {
                case .cexVolume: values = try await marketKit.cexVolumeRanks(currencyCode: currencyCode).map { .multi(value: $0) }
                case .dexVolume: values = try await marketKit.dexVolumeRanks(currencyCode: currencyCode).map { .multi(value: $0) }
                case .dexLiquidity: values = try await marketKit.dexLiquidityRanks().map { .single(value: $0) }
                case .address: values = try await marketKit.activeAddressRanks().map { .multi(value: $0) }
                case .txCount: values = try await marketKit.transactionCountRanks().map { .multi(value: $0) }
                case .holders: values = try await marketKit.holdersRanks().map { .single(value: $0) }
                case .fee: values = try await marketKit.feeRanks(currencyCode: currencyCode).map { .multi(value: $0) }
                case .revenue: values = try await marketKit.revenueRanks(currencyCode: currencyCode).map { .multi(value: $0) }
                }

                self?.handle(values: values)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
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

        let filteredItems = items.sorted { $0.value > $1.value }.prefix(300)
        let indexedItems = filteredItems.enumerated().map { index, item in
            IndexedItem(index: index + 1, coin: item.coin, value: item.value)
        }

        let sortedIndexedItems = sortDirectionAscending ? indexedItems.sorted { $0.value < $1.value } : indexedItems

        state = .loaded(items: sortedIndexedItems, reorder: reorder)
    }

}

extension CoinRankService {

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
        case loaded(items: [IndexedItem], reorder: Bool)
        case failed(error: Error)
    }

    private struct Item {
        let coin: Coin
        let value: Decimal
    }

    struct IndexedItem {
        let index: Int
        let coin: Coin
        let value: Decimal
    }

}
