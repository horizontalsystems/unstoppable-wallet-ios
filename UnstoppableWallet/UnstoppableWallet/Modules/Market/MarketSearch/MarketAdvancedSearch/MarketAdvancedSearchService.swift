import RxSwift
import RxRelay
import CoinKit
import CurrencyKit
import XRatesKit

class MarketAdvancedSearchService {
    private var disposeBag = DisposeBag()
    private let allTimeDeltaPercent: Decimal = 10

    private let rateManager: IRateManager
    private let currencyKit: CurrencyKit.Kit

    private var stateUpdatedRelay = PublishRelay<DataStatus<Int>>()
    private(set) var state: DataStatus<Int> = .loading {
        didSet {
            stateUpdatedRelay.accept(state)
        }
    }

    private var cache = [CoinMarket]()

    private var refetchRelay = PublishRelay<()>()

    private var coinListUpdatedRelay = PublishRelay<CoinListCount>()
    var coinListCount: CoinListCount = .top250 {
        didSet {
            guard coinListCount != oldValue else {
                return
            }

            coinListUpdatedRelay.accept(coinListCount)
            refreshCounter()
        }
    }

    private var periodUpdatedRelay = PublishRelay<PricePeriodFilter>()
    var period: PricePeriodFilter = .day {
        didSet {
            guard period != oldValue else {
                return
            }

            periodUpdatedRelay.accept(period)
            refreshCounter()
        }
    }

    private var marketCapUpdatedRelay = PublishRelay<ValueFilter>()
    var marketCap: ValueFilter = .none {
        didSet {
            guard marketCap != oldValue else {
                return
            }

            marketCapUpdatedRelay.accept(marketCap)
            updateFiltersIfNeeded()
        }
    }

    private var volumeUpdatedRelay = PublishRelay<ValueFilter>()
    var volume: ValueFilter = .none {
        didSet {
            guard volume != oldValue else {
                return
            }

            volumeUpdatedRelay.accept(volume)
            updateFiltersIfNeeded()
        }
    }

    private var liquidityUpdatedRelay = PublishRelay<ValueFilter>()
    var liquidity: ValueFilter = .none {
        didSet {
            guard liquidity != oldValue else {
                return
            }

            liquidityUpdatedRelay.accept(liquidity)
            updateFiltersIfNeeded()
        }
    }

    private var priceChangeUpdatedRelay = PublishRelay<PriceChangeFilter>()
    var priceChange: PriceChangeFilter = .none {
        didSet {
            guard priceChange != oldValue else {
                return
            }

            priceChangeUpdatedRelay.accept(priceChange)
            updateFiltersIfNeeded()
        }
    }

    private var outperformedBtcUpdatedRelay = PublishRelay<Bool>()
    var outperformedBtc: Bool = false {
        didSet {
            guard outperformedBtc != oldValue else {
                return
            }

            outperformedBtcUpdatedRelay.accept(outperformedBtc)
            updateFiltersIfNeeded()
        }
    }

    private var outperformedEthUpdatedRelay = PublishRelay<Bool>()
    var outperformedEth: Bool = false {
        didSet {
            guard outperformedEth != oldValue else {
                return
            }

            outperformedEthUpdatedRelay.accept(outperformedEth)
            updateFiltersIfNeeded()
        }
    }

    private var outperformedBnbUpdatedRelay = PublishRelay<Bool>()
    var outperformedBnb: Bool = false {
        didSet {
            guard outperformedBnb != oldValue else {
                return
            }

            outperformedBnbUpdatedRelay.accept(outperformedBnb)
            updateFiltersIfNeeded()
        }
    }

    private var priceCloseToATHUpdatedRelay = PublishRelay<Bool>()
    var priceCloseToATH: Bool = false {
        didSet {
            guard priceCloseToATH != oldValue else {
                return
            }

            priceCloseToATHUpdatedRelay.accept(priceCloseToATH)
            updateFiltersIfNeeded()
        }
    }

    private var priceCloseToATLUpdatedRelay = PublishRelay<Bool>()
    var priceCloseToATL: Bool = false {
        didSet {
            guard priceCloseToATL != oldValue else {
                return
            }

            priceCloseToATLUpdatedRelay.accept(priceCloseToATL)
            updateFiltersIfNeeded()
        }
    }

    init(rateManager: IRateManager, currencyKit: CurrencyKit.Kit) {
        self.rateManager = rateManager
        self.currencyKit = currencyKit

        refreshCounter()
    }

    private func refreshCounter() {
        disposeBag = DisposeBag()

        cache = []
        state = .loading

        topMarketList(currencyCode: currencyKit.baseCurrency.code).subscribe(onSuccess: { [weak self] in
            self?.sync(count: $0.count)
        }, onError: { [weak self] error in
            self?.state = .failed(error)
        }).disposed(by: disposeBag)
    }

    private func updateFiltersIfNeeded() {
        if case .completed = state {
            refetchRelay.accept(())
            state = .completed(filtered(items: cache).count)
        }
    }

    private func sync(count: Int) {
        refetchRelay.accept(())
        state = .completed(count)
    }

    private func topMarketList(currencyCode: String) -> Single<[(index: Int, item: CoinMarket)]> {
        let single: Single<[CoinMarket]>
        if cache.isEmpty {
            single = rateManager
                    .topMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: period.fetchDiffPeriod, itemCount: coinListCount.rawValue)
                    .do(onSuccess: { [weak self] in
                        self?.cache = $0
                    })
        } else {
            single = Single.just(cache)
        }

        return single
                .map { [weak self] in
                    self?.filtered(items: $0) ?? []
                }
    }

    private func coinMarket(coinType: CoinType) -> CoinMarket? {
        cache.first(where: { $0.coinData.coinType == coinType })
    }

    private func outperformed(value: Decimal?, coinType: CoinType) -> Bool {
        guard let coinMarket = coinMarket(coinType: coinType),
              let value = value,
              let diff = coinMarket.marketInfo.rateDiffPeriod else {

            return false
        }

        return diff < value
    }

    private func inBounds(value: Decimal?, lower: Decimal?, upper: Decimal?) -> Bool {
        guard let value = value else {
            return false
        }

        if let lower = lower, value < lower {
            return false
        }
        if let upper = upper, value > upper {
            return false
        }

        return true
    }

    private func closedToAllTime(value: Decimal?) -> Bool {
        guard let value = value else {
            return false
        }

        return abs(value) < allTimeDeltaPercent
    }

    private func filtered(items: [CoinMarket]) -> [(index: Int, item: CoinMarket)] {
        items.enumerated().compactMap { (index, item) in
            if
                //          inBounds(value: item.marketInfo.liquidity, lower: liquidity.lowerBound, upper: liquidity.upperBound) &&
                inBounds(value: item.marketInfo.marketCap, lower: marketCap.lowerBound, upper: marketCap.upperBound) &&
                inBounds(value: item.marketInfo.volume, lower: volume.lowerBound, upper: volume.upperBound) &&
                inBounds(value: item.marketInfo.rateDiffPeriod, lower: priceChange.lowerBound, upper: priceChange.upperBound) &&
                        (!priceCloseToATH || closedToAllTime(value: item.marketInfo.athChangePercentage)) &&
                        (!priceCloseToATL || closedToAllTime(value: item.marketInfo.atlChangePercentage)) &&
                        (!outperformedBtc || outperformed(value: item.marketInfo.rateDiffPeriod, coinType: .bitcoin)) &&
                        (!outperformedEth || outperformed(value: item.marketInfo.rateDiffPeriod, coinType: .ethereum)) &&
                        (!outperformedBnb || outperformed(value: item.marketInfo.rateDiffPeriod, coinType: .bep2(symbol: "BNB"))) {
                return (index: index, item: item)
            }
            return nil
        }
    }

}

extension MarketAdvancedSearchService {

    var coinListUpdatedObservable: Observable<CoinListCount> {
        coinListUpdatedRelay.asObservable()
    }

    var periodUpdatedObservable: Observable<PricePeriodFilter> {
        periodUpdatedRelay.asObservable()
    }

    var marketCapUpdatedObservable: Observable<ValueFilter> {
        marketCapUpdatedRelay.asObservable()
    }

    var volumeUpdatedObservable: Observable<ValueFilter> {
        volumeUpdatedRelay.asObservable()
    }

    var liquidityUpdatedObservable: Observable<ValueFilter> {
        liquidityUpdatedRelay.asObservable()
    }

    var priceChangeUpdatedObservable: Observable<PriceChangeFilter> {
        priceChangeUpdatedRelay.asObservable()
    }

    var outperformedBtcUpdatedObservable: Observable<Bool> {
        outperformedBtcUpdatedRelay.asObservable()
    }

    var outperformedEthUpdatedObservable: Observable<Bool> {
        outperformedEthUpdatedRelay.asObservable()
    }

    var outperformedBnbUpdatedObservable: Observable<Bool> {
        outperformedBnbUpdatedRelay.asObservable()
    }

    var priceCloseToATHUpdatedObservable: Observable<Bool> {
        priceCloseToATHUpdatedRelay.asObservable()
    }

    var priceCloseToATLUpdatedObservable: Observable<Bool> {
        priceCloseToATLUpdatedRelay.asObservable()
    }

    var stateUpdatedObservable: Observable<DataStatus<Int>> {
        stateUpdatedRelay.asObservable()
    }

}

extension MarketAdvancedSearchService: IMarketListFetcher {

    func fetchSingle(currencyCode: String) -> Single<[MarketModule.Item]> {
        topMarketList(currencyCode: currencyCode)
            .map { coinMarkets in
                coinMarkets.compactMap { pair in
                    MarketModule.Item(coinMarket: pair.item, score: .rank(pair.index + 1))
                }
            }
    }

    var refetchObservable: Observable<()> {
        refetchRelay.asObservable()
    }

}
extension MarketAdvancedSearchService {

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

        var lowerBound: Decimal? {
            switch self {
            case .none, .lessM5: return nil
            case .m5m20: return 5_000_000
            case .m20m100: return 20_000_000
            case .m100b1: return 100_000_000
            case .b1b5: return 1_000_000_000
            case .moreB5: return 5_000_000_000
            }
        }

        var upperBound: Decimal? {
            switch self {
            case .lessM5: return 5_000_000
            case .m5m20: return 20_000_000
            case .m20m100: return 100_000_000
            case .m100b1: return 1_000_000_000
            case .b1b5: return 5_000_000_000
            case .none, .moreB5: return nil
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

        var lowerBound: Decimal? {
            switch self {
            case .none: return nil
            case .plus10: return 10
            case .plus25: return 25
            case .plus50: return 50
            case .plus100: return 100
            case .minus10: return nil
            case .minus25: return nil
            case .minus50: return nil
            case .minus100: return nil
            }
        }

        var upperBound: Decimal? {
            switch self {
            case .none: return nil
            case .plus10: return nil
            case .plus25: return nil
            case .plus50: return nil
            case .plus100: return nil
            case .minus10: return -10
            case .minus25: return -25
            case .minus50: return -50
            case .minus100: return -100
            }
        }

    }

    enum PricePeriodFilter: CaseIterable {
        case day
        case week
        case week2
        case month
        case month6
        case year

        var fetchDiffPeriod: TimePeriod {
            switch self {
            case .day: return .hour24
            case .week: return .day7
            case .week2: return .day14
            case .month: return .day30
            case .month6: return .day200
            case .year: return .year1
            }
        }
    }

}
