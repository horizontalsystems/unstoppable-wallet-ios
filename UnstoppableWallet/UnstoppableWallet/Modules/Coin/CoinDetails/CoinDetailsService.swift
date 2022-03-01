import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import Chart

class CoinDetailsService {
    private var disposeBag = DisposeBag()

    private let fullCoin: FullCoin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit

    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(fullCoin: FullCoin, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.fullCoin = fullCoin
        self.marketKit = marketKit
        self.currencyKit = currencyKit
    }

    private func fetchCharts(details: MarketInfoDetails) -> Single<Item> {
        let tvlSingle: Single<[ChartPoint]>
        if details.tvl != nil {
            tvlSingle = marketKit.marketInfoTvlSingle(coinUid: fullCoin.coin.uid, currencyCode: currency.code, timePeriod: .month1)
        } else {
            tvlSingle = Single.just([])
        }

        let volumeSingle = marketKit
                .chartInfoSingle(coinUid: fullCoin.coin.uid, currencyCode: currency.code, interval: .month1)
                .map {
                    $0.points
                    .compactMap { point in
                        point.extra[ChartPoint.volume].map { ChartPoint(timestamp: point.timestamp, value: $0) }
                    }
                }

        return Single.zip(
                tvlSingle.catchErrorJustReturn([]),
                volumeSingle.catchErrorJustReturn([])
            ).map { tvls, totalVolumes -> Item in
                Item(marketInfoDetails: details, tvls: tvls, totalVolumes: totalVolumes)
        }
    }

}

extension CoinDetailsService {

    var stateObservable: Observable<DataStatus<Item>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var usdCurrency: Currency {
        let currencies = currencyKit.currencies
        return currencies.first { $0.code == "USD" } ?? currencies[0]
    }

    var coin: Coin {
        fullCoin.coin
    }

    var auditAddresses: [String] {
        fullCoin.supportedPlatforms.compactMap { platform in
            switch platform.coinType {
            case .erc20(let address): return address
            case .bep20(let address): return address
            default: return nil
            }
        }
    }

    var hasMajorHolders: Bool {
        for platform in fullCoin.supportedPlatforms {
            switch platform.coinType {
            case .erc20: return true
            default: ()
            }
        }

        return false
    }

    func sync() {
        disposeBag = DisposeBag()

        state = .loading

        marketKit.marketInfoDetailsSingle(coinUid: fullCoin.coin.uid, currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .flatMap { [weak self] details -> Single<Item> in
                    self?.fetchCharts(details: details) ?? Single.just(Item(marketInfoDetails: details))
                }
                .subscribe(onSuccess: { [weak self] info in
                    self?.state = .completed(info)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension CoinDetailsService {

    struct ChartItem {
        let chartData: ChartData?
        let chartTrend: MovementTrend
    }

    struct Item {
        let marketInfoDetails: MarketInfoDetails
        let tvls: [ChartPoint]?
        let totalVolumes: [ChartPoint]?

        init(marketInfoDetails: MarketInfoDetails, tvls: [ChartPoint]? = nil, totalVolumes: [ChartPoint]? = nil) {
            self.marketInfoDetails = marketInfoDetails
            self.tvls = tvls
            self.totalVolumes = totalVolumes
        }

    }

}
