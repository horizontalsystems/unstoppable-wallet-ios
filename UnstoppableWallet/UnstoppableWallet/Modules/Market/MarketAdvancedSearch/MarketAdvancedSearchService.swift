import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketAdvancedSearchService {
    private var disposeBag = DisposeBag()
    private let allTimeDeltaPercent: Decimal = 10

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    private var stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var coinListCountRelay = PublishRelay<CoinListCount>()
    var coinListCount: CoinListCount = .top250 {
        didSet {
            guard coinListCount != oldValue else {
                return
            }

            coinListCountRelay.accept(coinListCount)
            syncMarketInfos()
        }
    }

    private var marketCapRelay = PublishRelay<ValueFilter>()
    var marketCap: ValueFilter = .none {
        didSet {
            guard marketCap != oldValue else {
                return
            }

            marketCapRelay.accept(marketCap)
            syncState()
        }
    }

    private var volumeRelay = PublishRelay<ValueFilter>()
    var volume: ValueFilter = .none {
        didSet {
            guard volume != oldValue else {
                return
            }

            volumeRelay.accept(volume)
            syncState()
        }
    }


    private var priceChangeRelay = PublishRelay<PriceChangeFilter>()
    var priceChange: PriceChangeFilter = .none {
        didSet {
            guard priceChange != oldValue else {
                return
            }

            priceChangeRelay.accept(priceChange)
            syncState()
        }
    }

    private var priceChangeTypeRelay = PublishRelay<MarketModule.PriceChangeType>()
    var priceChangeType: MarketModule.PriceChangeType = .day {
        didSet {
            guard priceChangeType != oldValue else {
                return
            }

            priceChangeTypeRelay.accept(priceChangeType)
            syncState()
        }
    }

    private var outperformedBtcRelay = PublishRelay<Bool>()
    var outperformedBtc: Bool = false {
        didSet {
            guard outperformedBtc != oldValue else {
                return
            }

            outperformedBtcRelay.accept(outperformedBtc)
            syncState()
        }
    }

    private var outperformedEthRelay = PublishRelay<Bool>()
    var outperformedEth: Bool = false {
        didSet {
            guard outperformedEth != oldValue else {
                return
            }

            outperformedEthRelay.accept(outperformedEth)
            syncState()
        }
    }

    private var outperformedBnbRelay = PublishRelay<Bool>()
    var outperformedBnb: Bool = false {
        didSet {
            guard outperformedBnb != oldValue else {
                return
            }

            outperformedBnbRelay.accept(outperformedBnb)
            syncState()
        }
    }

    private var priceCloseToAthRelay = PublishRelay<Bool>()
    var priceCloseToAth: Bool = false {
        didSet {
            guard priceCloseToAth != oldValue else {
                return
            }

            priceCloseToAthRelay.accept(priceCloseToAth)
            syncState()
        }
    }

    private var priceCloseToAtlRelay = PublishRelay<Bool>()
    var priceCloseToAtl: Bool = false {
        didSet {
            guard priceCloseToAtl != oldValue else {
                return
            }

            priceCloseToAtlRelay.accept(priceCloseToAtl)
            syncState()
        }
    }

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        disposeBag = DisposeBag()

        internalState = .loading

        marketKit.advancedMarketInfosSingle(top: coinListCount.rawValue)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.internalState = .loaded(marketInfos: marketInfos)
                }, onError: { [weak self] error in
                    self?.internalState = .failed(error: error)
                })
                .disposed(by: disposeBag)
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case .loaded(let marketInfos):
            state = .loaded(marketInfos: filtered(marketInfos: marketInfos))
        case .failed(let error):
            state = .failed(error: error)
        }
    }

    private func marketInfo(coinUid: String) -> MarketInfo? {
        guard case .loaded(let marketInfos) = internalState else {
            return nil
        }

        return marketInfos.first { $0.fullCoin.coin.uid == coinUid }
    }

    private func inBounds(value: Decimal?, lower: Decimal, upper: Decimal) -> Bool {
        guard let value = value else {
            return false
        }

        return value >= lower && value <= upper
    }

    private func outperformed(value: Decimal?, coinUid: String) -> Bool {
        guard let marketInfo = marketInfo(coinUid: coinUid),
              let value = value,
              let priceChangeValue = marketInfo.priceChangeValue(type: priceChangeType) else {
            return false
        }

        return value > priceChangeValue
    }

    private func closedToAllTime(value: Decimal?) -> Bool {
        guard let value = value else {
            return false
        }

        return abs(value) < allTimeDeltaPercent
    }

    private func filtered(marketInfos: [MarketInfo]) -> [MarketInfo] {
        marketInfos.filter { marketInfo in
            let priceChangeValue = marketInfo.priceChangeValue(type: priceChangeType)

            return inBounds(value: marketInfo.marketCap, lower: marketCap.lowerBound, upper: marketCap.upperBound) &&
                    inBounds(value: marketInfo.totalVolume, lower: volume.lowerBound, upper: volume.upperBound) &&
                    inBounds(value: priceChangeValue, lower: priceChange.lowerBound, upper: priceChange.upperBound) &&
                    (!outperformedBtc || outperformed(value: priceChangeValue, coinUid: "bitcoin")) &&
                    (!outperformedEth || outperformed(value: priceChangeValue, coinUid: "ethereum")) &&
                    (!outperformedBnb || outperformed(value: priceChangeValue, coinUid: "binance-coin")) &&
                    (!priceCloseToAth || closedToAllTime(value: marketInfo.ath)) &&
                    (!priceCloseToAtl || closedToAllTime(value: marketInfo.atl))
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

    func reset() {
        coinListCount = .top250
        volume = .none
        marketCap = .none
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
        case m5m20
        case m20m100
        case m100b1
        case b1b5
        case moreB5

        var lowerBound: Decimal {
            switch self {
            case .none, .lessM5: return 0
            case .m5m20: return 5_000_000
            case .m20m100: return 20_000_000
            case .m100b1: return 100_000_000
            case .b1b5: return 1_000_000_000
            case .moreB5: return 5_000_000_000
            }
        }

        var upperBound: Decimal {
            switch self {
            case .lessM5: return 5_000_000
            case .m5m20: return 20_000_000
            case .m20m100: return 100_000_000
            case .m100b1: return 1_000_000_000
            case .b1b5: return 5_000_000_000
            case .none, .moreB5: return Decimal.greatestFiniteMagnitude
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
        case minus100

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
            case .minus100: return Decimal.leastFiniteMagnitude
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
            case .minus100: return -100
            }
        }

    }

}
