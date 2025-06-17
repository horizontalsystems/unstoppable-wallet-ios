import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketAdvancedSearchViewModel: ObservableObject {
    private let blockchainTypes: [BlockchainType] = [
        .ethereum,
        .binanceSmartChain,
        .arbitrumOne,
        .avalanche,
        .gnosis,
        .fantom,
        .unsupported(uid: "harmony"),
        .unsupported(uid: "huobi-token"),
        .unsupported(uid: "iotex"),
        .unsupported(uid: "moonriver"),
        .unsupported(uid: "okex-chain"),
        .optimism,
        .base,
        .polygon,
        .unsupported(uid: "solana"),
        .unsupported(uid: "sora"),
        .unsupported(uid: "tomochain"),
        .unsupported(uid: "xdai"),
    ]
    private let allTimeDeltaPercent: Decimal = 10

    private let marketKit = Core.shared.marketKit
    private let currencyManager = Core.shared.currencyManager
    private let priceChangeModeManager = Core.shared.priceChangeModeManager
    private let purchaseManager = Core.shared.purchaseManager

    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()
    private var categoriesTasks = Set<AnyTask>()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var advancedSearchEnabled: Bool = false

    @Published var top: MarketModule.Top = .default {
        didSet {
            guard top != oldValue else {
                return
            }

            syncMarketInfos()
        }
    }

    @Published var volume: ValueFilter = .none {
        didSet {
            syncState()
        }
    }

    @Published var allCategoriesState: CategoriesState = .loading
    @Published var categories: CategoryFilter = .any {
        didSet {
            syncState()
        }
    }

    @Published var listedOnTopExchanges = false {
        didSet {
            syncState()
        }
    }

    @Published var goodCexVolume = false {
        didSet {
            syncState()
        }
    }

    @Published var goodDexVolume = false {
        didSet {
            syncState()
        }
    }

    @Published var goodDistribution = false {
        didSet {
            syncState()
        }
    }

    @Published var blockchains = Set<Blockchain>() {
        didSet {
            syncState()
        }
    }

    @Published var signal: TechnicalAdvice.Advice? {
        didSet {
            syncState()
        }
    }

    @Published var priceCloseTo: PriceCloseToFilter = .none {
        didSet {
            syncState()
        }
    }

    @Published var priceChange: PriceChangeFilter = .none {
        didSet {
            syncState()
        }
    }

    @Published var priceChangePeriod: HsTimePeriod {
        didSet {
            syncState()
        }
    }

    @Published var outperformedBtc = false {
        didSet {
            syncState()
        }
    }

    @Published var outperformedEth = false {
        didSet {
            syncState()
        }
    }

    @Published var outperformedBnb = false {
        didSet {
            syncState()
        }
    }

    @Published var canReset = false

    let allBlockchains: [Blockchain]

    private var syncStateEnabled = true

    init() {
        do {
            let blockchains = try marketKit.blockchains(uids: blockchainTypes.map(\.uid))
            allBlockchains = blockchainTypes.compactMap { type in blockchains.first(where: { $0.type == type }) }
        } catch {
            allBlockchains = []
        }

        priceChangePeriod = priceChangeModeManager.day1Period

        priceChangeModeManager.$priceChangeMode
            .sink { [weak self] _ in
                if let strongSelf = self {
                    strongSelf.priceChangePeriod = strongSelf.priceChangeModeManager.day1Period
                }
            }
            .store(in: &cancellables)

        advancedSearchEnabled = purchaseManager.activated(.advancedSearch)
        purchaseManager.$activeFeatures
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeFeatures in
                self?.advancedSearchEnabled = activeFeatures.contains(.advancedSearch)
            }
            .store(in: &cancellables)

        syncMarketInfos()
        syncCategories()
    }

    private func syncCategories() {
        categoriesTasks = Set()

        Task { [weak self, marketKit, currencyManager] in
            await MainActor.run { [weak self] in
                self?.allCategoriesState = .loading
            }

            do {
                let categories = try await marketKit.coinCategories(currencyCode: currencyManager.baseCurrency.code)

                await MainActor.run { [weak self] in
                    self?.allCategoriesState = .loaded(categories: categories)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.allCategoriesState = .failed(error: error)
                }
            }
        }.store(in: &categoriesTasks)
    }

    private func syncState() {
        guard syncStateEnabled else {
            return
        }

        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(marketInfos):
            state = .loaded(marketInfos: filtered(marketInfos: marketInfos))
        case let .failed(error):
            state = .failed(error: error)
        }

        canReset = top != .default
            || volume != .none
            || categories != .any
            || listedOnTopExchanges != false
            || goodCexVolume != false
            || goodDexVolume != false
            || goodDistribution != false
            || !blockchains.isEmpty
            || signal != nil
            || priceChange != .none
            || priceChangePeriod != priceChangeModeManager.day1Period
            || outperformedBtc != false
            || outperformedEth != false
            || outperformedBnb != false
            || priceCloseTo != .none
    }

    private func filtered(marketInfos: [MarketInfo]) -> [MarketInfo] {
        marketInfos.filter { marketInfo in
            let priceChangeValue = marketInfo.priceChangeValue(timePeriod: priceChangePeriod)

            return
                inBounds(value: marketInfo.totalVolume, lower: volume.lowerBound, upper: volume.upperBound) &&
                inCategories(marketInfo: marketInfo) &&
                (!listedOnTopExchanges || marketInfo.listedOnTopExchanges == true) &&
                (!goodCexVolume || marketInfo.solidCex == true) &&
                (!goodDexVolume || marketInfo.solidDex == true) &&
                (!goodDistribution || marketInfo.goodDistribution == true) &&
                inBlockchain(tokens: marketInfo.fullCoin.tokens) &&
                filteredBySignal(marketInfo: marketInfo) &&
                inBounds(value: priceChangeValue, lower: priceChange.lowerBound, upper: priceChange.upperBound) &&
                (!outperformedBtc || outperformed(value: priceChangeValue, coinUid: "bitcoin")) &&
                (!outperformedEth || outperformed(value: priceChangeValue, coinUid: "ethereum")) &&
                (!outperformedBnb || outperformed(value: priceChangeValue, coinUid: "binancecoin")) &&
                closedToAllTime(closedTo: priceCloseTo, ath: marketInfo.athPercentage, atl: marketInfo.atlPercentage)
        }
    }

    private func inBounds(value: Decimal?, lower: Decimal, upper: Decimal) -> Bool {
        guard let value else {
            return false
        }

        return value >= lower && value <= upper
    }

    private func inBlockchain(tokens: [Token]?) -> Bool {
        guard !blockchains.isEmpty else {
            return true
        }

        guard let tokens else {
            return false
        }

        for token in tokens {
            if blockchains.contains(token.blockchain) {
                return true
            }
        }

        return false
    }

    private func inCategories(marketInfo: MarketInfo) -> Bool {
        switch categories {
        case .any: return true
        case let .list(array): return !Set(array).intersection(Set(marketInfo.categoryIds)).isEmpty
        }
    }

    private func filteredBySignal(marketInfo: MarketInfo) -> Bool {
        guard let signal else {
            return true
        }

        guard let infoAdvice = marketInfo.indicatorsResult else {
            return false
        }

        if signal.isRisky, infoAdvice.isRisky {
            return true
        }

        return signal == infoAdvice
    }

    private func outperformed(value: Decimal?, coinUid: String) -> Bool {
        guard let marketInfo = marketInfo(coinUid: coinUid),
              let value,
              let priceChangeValue = marketInfo.priceChangeValue(timePeriod: priceChangePeriod)
        else {
            return false
        }

        return value > priceChangeValue
    }

    private func marketInfo(coinUid: String) -> MarketInfo? {
        guard case let .loaded(marketInfos) = internalState else {
            return nil
        }

        return marketInfos.first { $0.fullCoin.coin.uid == coinUid }
    }

    private func closedToAllTime(closedTo: PriceCloseToFilter, ath: Decimal?, atl: Decimal?) -> Bool {
        var value: Decimal?
        switch closedTo {
        case .none: return true
        case .ath: value = ath
        case .atl: value = atl
        }

        guard let value else {
            return false
        }

        return abs(value) < allTimeDeltaPercent
    }
}

extension MarketAdvancedSearchViewModel {
    var tops: [MarketModule.Top] {
        MarketModule.Top.allCases
    }

    var valueFilters: [ValueFilter] {
        switch currencyManager.baseCurrency.code {
        case "USD": return [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5]
        case "EUR": return [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5]
        case "GBP": return [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5]
        case "JPY": return [.none, .lessM500, .m500b2, .b2b10, .b10b100, .b100b500, .moreB500]
        case "AUD": return [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5]
        case "BRL": return [.none, .lessM50, .m50m200, .m200b1, .b1b10, .b10b50, .moreB50]
        case "CAD": return [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5]
        case "CHF": return [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5]
        case "CNY": return [.none, .lessM50, .m50m200, .m200b1, .b1b10, .b10b50, .moreB50]
        case "HKD": return [.none, .lessM50, .m50m200, .m200b1, .b1b10, .b10b50, .moreB50]
        case "ILS": return [.none, .lessM10, .m10m40, .m40m200, .m200b2, .b2b10, .moreB10]
        case "RUB": return [.none, .lessM500, .m500b2, .b2b10, .b10b100, .b100b500, .moreB500]
        case "SGD": return [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5]
        default: return []
        }
    }

    var signals: [TechnicalAdvice.Advice] {
        [.strongBuy, .buy, .neutral, .sell, .strongSell, .overbought]
    }

    var priceChangePeriods: [HsTimePeriod] {
        [priceChangeModeManager.day1Period, .week1, .month1, .month3, .month6, .year1, .year2, .year3, .year4, .year5]
    }

    func syncMarketInfos() {
        tasks = Set()

        Task { [weak self, marketKit, top, currencyManager] in
            await MainActor.run { [weak self] in
                self?.internalState = .loading
            }

            do {
                let marketInfos = try await marketKit.advancedMarketInfos(top: top.rawValue, currencyCode: currencyManager.baseCurrency.code)

                await MainActor.run { [weak self] in
                    self?.internalState = .loaded(marketInfos: marketInfos)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.internalState = .failed(error: error)
                }
            }
        }.store(in: &tasks)
    }

    func reset() {
        syncStateEnabled = false

        top = .default
        volume = .none
        categories = .any
        listedOnTopExchanges = false
        goodDexVolume = false
        goodCexVolume = false
        goodDistribution = false
        blockchains = Set()
        signal = nil
        priceChange = .none
        priceChangePeriod = priceChangeModeManager.day1Period
        outperformedBtc = false
        outperformedEth = false
        outperformedBnb = false
        priceCloseTo = .none

        syncStateEnabled = true
        syncState()
    }
}

extension MarketAdvancedSearchViewModel {
    enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }

    enum CategoriesState {
        case loading
        case loaded(categories: [CoinCategory])
        case failed(error: Error)
    }

    enum CategoryFilter: Identifiable, Equatable {
        case any
        case list([Int])

        var id: String {
            switch self {
            case .any: return "any"
            case let .list(array): return array.sorted().map(\.description).joined(separator: "|")
            }
        }

        var title: String {
            switch self {
            case .any: return "selector.any".localized
            case let .list(array): return array.count.description
            }
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.any, .any): return true
            case (.list, .list): return lhs.id == rhs.id
            default: return false
            }
        }

        func include(id: Int) -> Bool {
            if case let .list(array) = self {
                return array.firstIndex(of: id) != nil
            }
            return false
        }
    }

    enum ValueFilter: CaseIterable, Identifiable {
        case none
        case lessM5
        case lessM10
        case lessM50
        case lessM500
        case m5m20
        case m10m40
        case m20m100
        case m40m200
        case m50m200
        case m100b1
        case m200b1
        case m200b2
        case m500b2
        case b1b5
        case b1b10
        case b2b10
        case b10b50
        case b10b100
        case b100b500
        case moreB5
        case moreB10
        case moreB50
        case moreB500

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .none: return "selector.any".localized
            case .lessM5: return "market.advanced_search.less_5_m".localized
            case .lessM10: return "market.advanced_search.less_10_m".localized
            case .lessM50: return "market.advanced_search.less_50_m".localized
            case .lessM500: return "market.advanced_search.less_500_m".localized
            case .m5m20: return "market.advanced_search.m_5_m_20".localized
            case .m10m40: return "market.advanced_search.m_10_m_40".localized
            case .m40m200: return "market.advanced_search.m_40_m_200".localized
            case .m50m200: return "market.advanced_search.m_50_m_200".localized
            case .m20m100: return "market.advanced_search.m_20_m_100".localized
            case .m100b1: return "market.advanced_search.m_100_b_1".localized
            case .m200b1: return "market.advanced_search.m_200_b_1".localized
            case .m200b2: return "market.advanced_search.m_200_b_2".localized
            case .m500b2: return "market.advanced_search.m_500_b_2".localized
            case .b1b5: return "market.advanced_search.b_1_b_5".localized
            case .b1b10: return "market.advanced_search.b_1_b_10".localized
            case .b2b10: return "market.advanced_search.b_2_b_10".localized
            case .b10b50: return "market.advanced_search.b_10_b_50".localized
            case .b10b100: return "market.advanced_search.b_10_b_100".localized
            case .b100b500: return "market.advanced_search.b_100_b_500".localized
            case .moreB5: return "market.advanced_search.more_5_b".localized
            case .moreB10: return "market.advanced_search.more_10_b".localized
            case .moreB50: return "market.advanced_search.more_50_b".localized
            case .moreB500: return "market.advanced_search.more_500_b".localized
            }
        }

        var lowerBound: Decimal {
            switch self {
            case .none, .lessM5, .lessM10, .lessM50, .lessM500: return 0
            case .m5m20: return 5_000_000
            case .m10m40: return 10_000_000
            case .m20m100: return 20_000_000
            case .m40m200: return 40_000_000
            case .m50m200: return 50_000_000
            case .m100b1: return 100_000_000
            case .m200b1, .m200b2: return 200_000_000
            case .m500b2: return 500_000_000
            case .b1b5, .b1b10: return 1_000_000_000
            case .b2b10: return 2_000_000_000
            case .b10b50, .b10b100: return 10_000_000_000
            case .b100b500: return 100_000_000_000
            case .moreB5: return 5_000_000_000
            case .moreB10: return 10_000_000_000
            case .moreB50: return 50_000_000_000
            case .moreB500: return 500_000_000_000
            }
        }

        var upperBound: Decimal {
            switch self {
            case .lessM5: return 5_000_000
            case .lessM10: return 10_000_000
            case .lessM50: return 50_000_000
            case .lessM500: return 500_000_000
            case .m5m20: return 20_000_000
            case .m10m40: return 40_000_000
            case .m20m100: return 100_000_000
            case .m40m200, .m50m200: return 200_000_000
            case .m100b1, .m200b1: return 1_000_000_000
            case .m200b2, .m500b2: return 2_000_000_000
            case .b1b5: return 5_000_000_000
            case .b1b10, .b2b10: return 10_000_000_000
            case .b10b50: return 50_000_000_000
            case .b10b100: return 100_000_000_000
            case .b100b500: return 500_000_000_000
            case .none, .moreB5, .moreB10, .moreB50, .moreB500: return Decimal.greatestFiniteMagnitude
            }
        }
    }

    enum PriceCloseToFilter: CaseIterable, Identifiable {
        case none
        case ath
        case atl

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .none: return "selector.none".localized
            case .ath: return "market.advanced_search.price_close_to_ath".localized
            case .atl: return "market.advanced_search.price_close_to_atl".localized
            }
        }
    }

    enum PriceChangeFilter: CaseIterable, Identifiable {
        case none
        case plus10
        case plus25
        case plus50
        case plus100
        case minus10
        case minus25
        case minus50
        case minus75

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .none: return "selector.any".localized
            case .plus10: return "> +10 %"
            case .plus25: return "> +25 %"
            case .plus50: return "> +50 %"
            case .plus100: return "> +100 %"
            case .minus10: return "< -10 %"
            case .minus25: return "< -25 %"
            case .minus50: return "< -50 %"
            case .minus75: return "< -75 %"
            }
        }

        var lowerBound: Decimal {
            switch self {
            case .none: return Decimal.leastFiniteMagnitude
            case .plus10: return 10
            case .plus25: return 25
            case .plus50: return 50
            case .plus100: return 100
            case .minus10: return Decimal.leastFiniteMagnitude
            case .minus25: return Decimal.leastFiniteMagnitude
            case .minus50: return Decimal.leastFiniteMagnitude
            case .minus75: return Decimal.leastFiniteMagnitude
            }
        }

        var upperBound: Decimal {
            switch self {
            case .none: return Decimal.greatestFiniteMagnitude
            case .plus10: return Decimal.greatestFiniteMagnitude
            case .plus25: return Decimal.greatestFiniteMagnitude
            case .plus50: return Decimal.greatestFiniteMagnitude
            case .plus100: return Decimal.greatestFiniteMagnitude
            case .minus10: return -10
            case .minus25: return -25
            case .minus50: return -50
            case .minus75: return -75
            }
        }
    }
}
