import Combine
import Foundation
import HsExtensions
import MarketKit

class RankViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    let type: CoinRankModule.RankType

    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var internalState: InternalState = .loading {
        didSet {
            syncState()
        }
    }

    @Published var state: State = .loading

    var sortOrder: MarketModule.SortOrder = .desc {
        didSet {
            stat(page: type.statRankType, event: .toggleSortDirection)
            syncState()
        }
    }

    var timePeriod: HsTimePeriod = .month1 {
        didSet {
            stat(page: type.statRankType, event: .switchPeriod(period: timePeriod.statPeriod))
            syncState()
        }
    }

    init(type: CoinRankModule.RankType) {
        self.type = type

        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.sync()
            }
            .store(in: &cancellables)

        sync()
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(items):
            let items = items.compactMap { item in
                switch item {
                case let .single(coin, single): return single.value.map { (coin: coin, value: $0) }
                case let .multi(coin, multi): return multi.value(timePeriod: timePeriod).map { (coin: coin, value: $0) }
                }
            }

            let filteredItems = items.sorted { $0.value > $1.value }.prefix(300)
            let indexedItems = filteredItems.enumerated().map { index, item in
                Item(index: index + 1, coin: item.coin, value: item.value)
            }

            let sortedItems = sortOrder.isAsc ? indexedItems.sorted { $0.value < $1.value } : indexedItems

            state = .loaded(items: sortedItems)
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension RankViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var timePeriods: [HsTimePeriod] {
        switch type {
        case .dexLiquidity, .holders: return [.month1]
        default: return [.day1, .week1, .month1]
        }
    }

    func sync() {
        tasks = Set()

        if case .failed = internalState {
            internalState = .loading
        }

        let code = currency.code

        Task { [weak self, marketKit, type] in
            do {
                let values: [Value]
                let coins = try marketKit.allCoins()

                var coinMap = [String: Coin]()
                coins.forEach { coinMap[$0.uid] = $0 }

                let multiMap: (RankMultiValue) -> Value? = { multi in
                    coinMap[multi.uid].map { .multi(coin: $0, value: multi) }
                }

                let singleMap: (RankValue) -> Value? = { value in
                    coinMap[value.uid].map { .single(coin: $0, value: value) }
                }

                switch type {
                case .cexVolume: values = try await marketKit.cexVolumeRanks(currencyCode: code).compactMap { multiMap($0) }
                case .dexVolume: values = try await marketKit.dexVolumeRanks(currencyCode: code).compactMap { multiMap($0) }
                case .dexLiquidity: values = try await marketKit.dexLiquidityRanks().compactMap { singleMap($0) }
                case .address: values = try await marketKit.activeAddressRanks().compactMap { multiMap($0) }
                case .txCount: values = try await marketKit.transactionCountRanks().compactMap { multiMap($0) }
                case .holders: values = try await marketKit.holdersRanks().compactMap { singleMap($0) }
                case .fee: values = try await marketKit.feeRanks(currencyCode: code).compactMap { multiMap($0) }
                case .revenue: values = try await marketKit.revenueRanks(currencyCode: code).compactMap { multiMap($0) }
                }

                await MainActor.run { [weak self] in
                    self?.internalState = .loaded(values: values)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.internalState = .failed(error: error)
                }
            }
        }
        .store(in: &tasks)
    }
}

extension RankViewModel {
    private enum InternalState {
        case loading
        case loaded(values: [Value])
        case failed(error: Error)
    }

    private enum Value {
        case multi(coin: Coin, value: RankMultiValue)
        case single(coin: Coin, value: RankValue)

        var coinUid: String {
            switch self {
            case let .multi(_, value): return value.uid
            case let .single(_, value): return value.uid
            }
        }
    }

    enum State {
        case loading
        case loaded(items: [Item])
        case failed(error: Error)
    }

    struct Item: Hashable {
        let index: Int
        let coin: Coin
        let value: Decimal

        public func hash(into hasher: inout Hasher) {
            hasher.combine(index)
            hasher.combine(coin.uid)
        }
    }
}

extension RankMultiValue {
    func value(timePeriod: HsTimePeriod) -> Decimal? {
        switch timePeriod {
        case .day1: return value1d
        case .week1: return value7d
        case .month1: return value30d
        default: return value1d
        }
    }
}

extension CoinRankModule.RankType {
    var title: String {
        switch self {
        case .cexVolume: return "coin_analytics.cex_volume_rank".localized
        case .dexVolume: return "coin_analytics.dex_volume_rank".localized
        case .dexLiquidity: return "coin_analytics.dex_liquidity_rank".localized
        case .address: return "coin_analytics.active_addresses_rank".localized
        case .txCount: return "coin_analytics.transaction_count_rank".localized
        case .holders: return "coin_analytics.holders_rank".localized
        case .fee: return "coin_analytics.project_fee_rank".localized
        case .revenue: return "coin_analytics.project_revenue_rank".localized
        }
    }

    var description: String {
        switch self {
        case .cexVolume: return "coin_analytics.cex_volume_rank.description".localized
        case .dexVolume: return "coin_analytics.dex_volume_rank.description".localized
        case .dexLiquidity: return "coin_analytics.dex_liquidity_rank.description".localized
        case .address: return "coin_analytics.active_addresses_rank.description".localized
        case .txCount: return "coin_analytics.transaction_count_rank.description".localized
        case .holders: return "coin_analytics.holders_rank.description".localized
        case .fee: return "coin_analytics.project_fee_rank.description".localized
        case .revenue: return "coin_analytics.project_revenue_rank.description".localized
        }
    }

    var imageUid: String {
        switch self {
        case .cexVolume: return "cex_volume"
        case .dexVolume: return "dex_volume"
        case .dexLiquidity: return "dex_liquidity"
        case .address: return "active_addresses"
        case .txCount: return "trx_count"
        case .holders: return "holders"
        case .fee: return "fee"
        case .revenue: return "revenue"
        }
    }

    var sortingField: String {
        switch self {
        case .cexVolume: return "coin_analytics.cex_volume_rank.sorting_field".localized
        case .dexVolume: return "coin_analytics.dex_volume_rank.sorting_field".localized
        case .dexLiquidity: return "coin_analytics.dex_liquidity_rank.sorting_field".localized
        case .address: return "coin_analytics.active_addresses_rank.sorting_field".localized
        case .txCount: return "coin_analytics.transaction_count_rank.sorting_field".localized
        case .holders: return "coin_analytics.holders_rank.sorting_field".localized
        case .fee: return "coin_analytics.project_fee_rank.sorting_field".localized
        case .revenue: return "coin_analytics.project_revenue_rank.sorting_field".localized
        }
    }
}
