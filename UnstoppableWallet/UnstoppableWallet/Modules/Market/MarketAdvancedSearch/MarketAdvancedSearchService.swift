import Foundation
import HsExtensions
import MarketKit
import RxRelay
import RxSwift

class MarketAdvancedSearchService {
    private let blockchainTypes: [BlockchainType] = [
        .ethereum,
        .binanceSmartChain,
        .binanceChain,
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
        .polygon,
        .unsupported(uid: "solana"),
        .unsupported(uid: "sora"),
        .unsupported(uid: "tomochain"),
        .unsupported(uid: "xdai"),
    ]

    private var tasks = Set<AnyTask>()
    private let allTimeDeltaPercent: Decimal = 10

    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let coinListCountRelay = PublishRelay<CoinListCount>()
    var coinListCount: CoinListCount = .top250 {
        didSet {
            guard coinListCount != oldValue else {
                return
            }

            coinListCountRelay.accept(coinListCount)
            syncMarketInfos()
        }
    }

    private let marketCapRelay = PublishRelay<ValueFilter>()
    var marketCap: ValueFilter = .none {
        didSet {
            guard marketCap != oldValue else {
                return
            }

            marketCapRelay.accept(marketCap)
            syncState()
        }
    }

    private let volumeRelay = PublishRelay<ValueFilter>()
    var volume: ValueFilter = .none {
        didSet {
            guard volume != oldValue else {
                return
            }

            volumeRelay.accept(volume)
            syncState()
        }
    }

    private let listedOnTopExchangesRelay = PublishRelay<Bool>()
    var listedOnTopExchanges: Bool = false {
        didSet {
            guard listedOnTopExchanges != oldValue else {
                return
            }

            listedOnTopExchangesRelay.accept(listedOnTopExchanges)
            syncState()
        }
    }

    private let goodCexVolumeRelay = PublishRelay<Bool>()
    var goodCexVolume: Bool = false {
        didSet {
            guard goodCexVolume != oldValue else {
                return
            }

            goodCexVolumeRelay.accept(goodCexVolume)
            syncState()
        }
    }

    private let goodDexVolumeRelay = PublishRelay<Bool>()
    var goodDexVolume: Bool = false {
        didSet {
            guard goodDexVolume != oldValue else {
                return
            }

            goodDexVolumeRelay.accept(goodDexVolume)
            syncState()
        }
    }

    private let goodDistributionRelay = PublishRelay<Bool>()
    var goodDistribution: Bool = false {
        didSet {
            guard goodDistribution != oldValue else {
                return
            }

            goodDistributionRelay.accept(goodDistribution)
            syncState()
        }
    }

    private let blockchainsRelay = PublishRelay<[Blockchain]>()
    var blockchains: [Blockchain] = [] {
        didSet {
            guard blockchains != oldValue else {
                return
            }

            blockchainsRelay.accept(blockchains)
            syncState()
        }
    }

    private let priceChangeRelay = PublishRelay<PriceChangeFilter>()
    var priceChange: PriceChangeFilter = .none {
        didSet {
            guard priceChange != oldValue else {
                return
            }

            priceChangeRelay.accept(priceChange)
            syncState()
        }
    }

    private let priceChangeTypeRelay = PublishRelay<MarketModule.PriceChangeType>()
    var priceChangeType: MarketModule.PriceChangeType = .day {
        didSet {
            guard priceChangeType != oldValue else {
                return
            }

            priceChangeTypeRelay.accept(priceChangeType)
            syncState()
        }
    }

    private let outperformedBtcRelay = PublishRelay<Bool>()
    var outperformedBtc: Bool = false {
        didSet {
            guard outperformedBtc != oldValue else {
                return
            }

            outperformedBtcRelay.accept(outperformedBtc)
            syncState()
        }
    }

    private let outperformedEthRelay = PublishRelay<Bool>()
    var outperformedEth: Bool = false {
        didSet {
            guard outperformedEth != oldValue else {
                return
            }

            outperformedEthRelay.accept(outperformedEth)
            syncState()
        }
    }

    private let outperformedBnbRelay = PublishRelay<Bool>()
    var outperformedBnb: Bool = false {
        didSet {
            guard outperformedBnb != oldValue else {
                return
            }

            outperformedBnbRelay.accept(outperformedBnb)
            syncState()
        }
    }

    private let priceCloseToAthRelay = PublishRelay<Bool>()
    var priceCloseToAth: Bool = false {
        didSet {
            guard priceCloseToAth != oldValue else {
                return
            }

            priceCloseToAthRelay.accept(priceCloseToAth)
            syncState()
        }
    }

    private let priceCloseToAtlRelay = PublishRelay<Bool>()
    var priceCloseToAtl: Bool = false {
        didSet {
            guard priceCloseToAtl != oldValue else {
                return
            }

            priceCloseToAtlRelay.accept(priceCloseToAtl)
            syncState()
        }
    }

    private var canResetRelay = PublishRelay<Bool>()
    private(set) var canReset: Bool = false {
        didSet {
            if canReset != oldValue {
                canResetRelay.accept(canReset)
            }
        }
    }

    var currencyCode: String {
        currencyManager.baseCurrency.code
    }

    let allBlockchains: [Blockchain]

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager

        do {
            let blockchains = try marketKit.blockchains(uids: blockchainTypes.map(\.uid))
            allBlockchains = blockchainTypes.compactMap { type in blockchains.first(where: { $0.type == type }) }
        } catch {
            allBlockchains = []
        }

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        tasks = Set()

        internalState = .loading

        Task { [weak self, marketKit, coinListCount, currencyManager] in
            do {
                let marketInfos = try await marketKit.advancedMarketInfos(top: coinListCount.rawValue, currencyCode: currencyManager.baseCurrency.code)
                self?.internalState = .loaded(marketInfos: marketInfos)
            } catch {
                self?.internalState = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(marketInfos):
            state = .loaded(marketInfos: filtered(marketInfos: marketInfos))
        case let .failed(error):
            state = .failed(error: error)
        }

        canReset = coinListCount != .top250
            || marketCap != .none
            || volume != .none
            || listedOnTopExchanges != false
            || goodCexVolume != false
            || goodDexVolume != false
            || goodDistribution != false
            || blockchains != []
            || priceChangeType != .day
            || priceChange != .none
            || outperformedBtc != false
            || outperformedEth != false
            || outperformedBnb != false
            || priceCloseToAtl != false
            || priceCloseToAth != false
    }

    private func marketInfo(coinUid: String) -> MarketInfo? {
        guard case let .loaded(marketInfos) = internalState else {
            return nil
        }

        return marketInfos.first { $0.fullCoin.coin.uid == coinUid }
    }

    private func inBounds(value: Decimal?, lower: Decimal, upper: Decimal) -> Bool {
        guard let value else {
            return false
        }

        return value >= lower && value <= upper
    }

    private func outperformed(value: Decimal?, coinUid: String) -> Bool {
        guard let marketInfo = marketInfo(coinUid: coinUid),
              let value,
              let priceChangeValue = marketInfo.priceChangeValue(type: priceChangeType)
        else {
            return false
        }

        return value > priceChangeValue
    }

    private func closedToAllTime(value: Decimal?) -> Bool {
        guard let value else {
            return false
        }

        return abs(value) < allTimeDeltaPercent
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

    private func filtered(marketInfos: [MarketInfo]) -> [MarketInfo] {
        marketInfos.filter { marketInfo in
            let priceChangeValue = marketInfo.priceChangeValue(type: priceChangeType)

            return inBounds(value: marketInfo.marketCap, lower: marketCap.lowerBound, upper: marketCap.upperBound) &&
                inBounds(value: marketInfo.totalVolume, lower: volume.lowerBound, upper: volume.upperBound) &&
                (!listedOnTopExchanges || marketInfo.listedOnTopExchanges == true) &&
                (!goodCexVolume || marketInfo.solidCex == true) &&
                (!goodDexVolume || marketInfo.solidDex == true) &&
                (!goodDistribution || marketInfo.goodDistribution == true) &&
                inBlockchain(tokens: marketInfo.fullCoin.tokens) &&
                inBounds(value: priceChangeValue, lower: priceChange.lowerBound, upper: priceChange.upperBound) &&
                (!outperformedBtc || outperformed(value: priceChangeValue, coinUid: "bitcoin")) &&
                (!outperformedEth || outperformed(value: priceChangeValue, coinUid: "ethereum")) &&
                (!outperformedBnb || outperformed(value: priceChangeValue, coinUid: "binancecoin")) &&
                (!priceCloseToAth || closedToAllTime(value: marketInfo.athPercentage)) &&
                (!priceCloseToAtl || closedToAllTime(value: marketInfo.atlPercentage))
        }
    }
}

extension MarketAdvancedSearchService {
    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var coinListObservable: Observable<CoinListCount> {
        coinListCountRelay.asObservable()
    }

    var marketCapObservable: Observable<ValueFilter> {
        marketCapRelay.asObservable()
    }

    var volumeObservable: Observable<ValueFilter> {
        volumeRelay.asObservable()
    }

    var listedOnTopExchangesObservable: Observable<Bool> {
        listedOnTopExchangesRelay.asObservable()
    }

    var goodCexVolumeObservable: Observable<Bool> {
        goodCexVolumeRelay.asObservable()
    }

    var goodDexVolumeObservable: Observable<Bool> {
        goodDexVolumeRelay.asObservable()
    }

    var goodDistributionObservable: Observable<Bool> {
        goodDistributionRelay.asObservable()
    }

    var blockchainsObservable: Observable<[Blockchain]> {
        blockchainsRelay.asObservable()
    }

    var priceChangeObservable: Observable<PriceChangeFilter> {
        priceChangeRelay.asObservable()
    }

    var priceChangeTypeObservable: Observable<MarketModule.PriceChangeType> {
        priceChangeTypeRelay.asObservable()
    }

    var outperformedBtcObservable: Observable<Bool> {
        outperformedBtcRelay.asObservable()
    }

    var outperformedEthObservable: Observable<Bool> {
        outperformedEthRelay.asObservable()
    }

    var outperformedBnbObservable: Observable<Bool> {
        outperformedBnbRelay.asObservable()
    }

    var priceCloseToAthObservable: Observable<Bool> {
        priceCloseToAthRelay.asObservable()
    }

    var priceCloseToAtlObservable: Observable<Bool> {
        priceCloseToAtlRelay.asObservable()
    }

    var canResetObservable: Observable<Bool> {
        canResetRelay.asObservable()
    }

    func reset() {
        coinListCount = .top250
        marketCap = .none
        volume = .none

        listedOnTopExchanges = false
        goodDexVolume = false
        goodCexVolume = false
        goodDistribution = false

        blockchains = []
        priceChangeType = .day
        priceChange = .none

        outperformedBtc = false
        outperformedEth = false
        outperformedBnb = false
        priceCloseToAtl = false
        priceCloseToAth = false
    }
}

extension MarketAdvancedSearchService {
    enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }

    enum CoinListCount: Int, CaseIterable {
        case top100 = 100
        case top250 = 250
        case top500 = 500
        case top1000 = 1000
        case top1500 = 1500
    }

    enum ValueFilter: CaseIterable {
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

    enum PriceChangeFilter: CaseIterable {
        case none
        case plus10
        case plus25
        case plus50
        case plus100
        case minus10
        case minus25
        case minus50
        case minus75

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
