import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import Chart

class CoinAnalyticsService {
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

    private func fetchCharts(details: MarketInfoDetails, analyticData: AnalyticData) -> Single<Item> {
        let tvlSingle: Single<[ChartPoint]>
        if details.tvl != nil {
            tvlSingle = marketKit.marketInfoTvlSingle(coinUid: fullCoin.coin.uid, currencyCode: currency.code, timePeriod: .month1)
        } else {
            tvlSingle = Single.just([])
        }

        return tvlSingle.catchErrorJustReturn([])
                .map { tvls -> Item in
                    Item(marketInfoDetails: details, analytics: analyticData, tvls: tvls)
                }
    }

    private func analyticData(coinUid: String, currencyCode: String) -> Single<AnalyticData> {
            let dexVolumeSingle = marketKit
                    .dexVolumesSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: .month1)
                    .catchErrorJustReturn(.empty)

            let dexLiquiditySingle = marketKit
                    .dexLiquiditySingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: .month1)
                    .catchErrorJustReturn(.empty)

            let transactionDataSingle = marketKit
                    .transactionDataSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: .month1, platform: nil)
                    .catchErrorJustReturn(.empty)

            let activeAddressesSingle = marketKit
                    .activeAddressesSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: .month1, platform: nil)
                    .catchErrorJustReturn(.empty)

            return Single.zip(dexVolumeSingle, dexLiquiditySingle, transactionDataSingle, activeAddressesSingle) { dexVolumeResponse, dexLiquidityResponse, transactionDataResponse, activeAddressesResponse in
                let dexVolumeChartPoints = dexVolumeResponse.volumePoints
                let dexLiquidityChartPoints = dexLiquidityResponse.volumePoints
                let txCountChartPoints = transactionDataResponse.countPoints
                let txVolumeChartPoints = transactionDataResponse.volumePoints
                let activeAddresses = activeAddressesResponse.countPoints

                return AnalyticData(
                        dexVolumes: .value(dexVolumeChartPoints),
                        dexLiquidity: .value(dexLiquidityChartPoints),
                        txCount: .value(txCountChartPoints),
                        txVolume: .value(txVolumeChartPoints),
                        activeAddresses: .value(activeAddresses)
                )
            }
    }

}

extension CoinAnalyticsService {

    var stateObservable: Observable<DataStatus<Item>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var usdCurrency: Currency {
        let currencies = currencyKit.currencies
        return currencies.first {
            $0.code == "USD"
        } ?? currencies[0]
    }

    var coin: Coin {
        fullCoin.coin
    }

    var auditAddresses: [String] {
        fullCoin.tokens.compactMap { token in
            switch (token.blockchainType, token.type) {
            case (.ethereum, .eip20(let address)): return address
            case (.binanceSmartChain, .eip20(let address)): return address
            default: return nil
            }
        }
    }

    var hasMajorHolders: Bool {
        for token in fullCoin.tokens {
            switch (token.blockchainType, token.type) {
            case (.ethereum, .eip20): return true
            default: ()
            }
        }

        return false
    }

    func sync() {
        disposeBag = DisposeBag()

        state = .loading

        return Single.zip(
                        marketKit.marketInfoDetailsSingle(coinUid: fullCoin.coin.uid, currencyCode: currency.code),
                        analyticData(coinUid: fullCoin.coin.uid, currencyCode: currency.code))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .flatMap { [weak self] (details, analyticData) -> Single<Item> in
                    self?.fetchCharts(details: details, analyticData: analyticData) ?? Single.just(Item(marketInfoDetails: details, analytics: .empty, tvls: nil))
                }
                .subscribe(onSuccess: { [weak self] info in
                    self?.state = .completed(info)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension CoinAnalyticsService {

    struct ChartItem {
        let chartData: ChartData?
        let chartTrend: MovementTrend
    }

    enum ProData {
        case empty
        case completed([ChartPoint])

        static func value(_ points: [ChartPoint]) -> Self {
            points.isEmpty ? .empty : .completed(points)
        }
    }

    struct AnalyticData {
        static var empty: AnalyticData {
            Self(dexVolumes: .empty, dexLiquidity: .empty, txCount: .empty, txVolume: .empty, activeAddresses: .empty)
        }

        let dexVolumes: ProData
        let dexLiquidity: ProData
        let txCount: ProData
        let txVolume: ProData
        let activeAddresses: ProData
    }

    struct Item {
        let marketInfoDetails: MarketInfoDetails
        let analytics: AnalyticData
        let tvls: [ChartPoint]?
    }

}
