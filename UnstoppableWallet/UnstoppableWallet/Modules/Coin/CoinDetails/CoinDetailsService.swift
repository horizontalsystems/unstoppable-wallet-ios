import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import Chart

class CoinDetailsService {
    private let proFeaturesUpdateDisposeBag = DisposeBag()
    private var disposeBag = DisposeBag()

    private let fullCoin: FullCoin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let proFeaturesManager: ProFeaturesAuthorizationManager

    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(fullCoin: FullCoin, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, proFeaturesManager: ProFeaturesAuthorizationManager) {
        self.fullCoin = fullCoin
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.proFeaturesManager = proFeaturesManager

        subscribe(proFeaturesUpdateDisposeBag, proFeaturesManager.sessionKeyObservable) { [weak self] _ in self?.sync() }
    }

    private func fetchCharts(details: MarketInfoDetails, proFeatures: ProFeatures) -> Single<Item> {
        let tvlSingle: Single<[ChartPoint]>
        if details.tvl != nil {
            tvlSingle = marketKit.marketInfoTvlSingle(coinUid: fullCoin.coin.uid, currencyCode: currency.code, timePeriod: .month1)
        } else {
            tvlSingle = Single.just([])
        }

        return tvlSingle.catchErrorJustReturn([])
                .map { tvls -> Item in
                    Item(marketInfoDetails: details, proFeatures: proFeatures, tvls: tvls)
                }
    }

    private func proFeatures(coinUid: String, currencyCode: String) -> Single<ProFeatures> {
        Single.just(ProFeatures.forbidden)
//
//        if let sessionKey = proFeaturesManager.sessionKey(type: .mountainYak) {
//            //request needed charts for pro state
//            let dexVolumeSingle = marketKit
//                    .dexVolumesSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: .month1, sessionKey: sessionKey)
//                    .catchErrorJustReturn(.empty)
//
//            let dexLiquiditySingle = marketKit
//                    .dexLiquiditySingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: .month1, sessionKey: sessionKey)
//                    .catchErrorJustReturn(.empty)
//
//            let transactionDataSingle = marketKit
//                    .transactionDataSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: .month1, platform: nil, sessionKey: sessionKey)
//                    .catchErrorJustReturn(.empty)
//
//            let activeAddressesSingle = marketKit
//                    .activeAddressesSingle(coinUid: coinUid, currencyCode: currencyCode, timePeriod: .month1, sessionKey: sessionKey)
//                    .catchErrorJustReturn([])
//
//            return Single.zip(dexVolumeSingle, dexLiquiditySingle, transactionDataSingle, activeAddressesSingle) { dexVolumeResponse, dexLiquidityResponse, transactionDataResponse, activeAddressesResponse in
//                let dexVolumeChartPoints = dexVolumeResponse.volumePoints
//                let dexLiquidityChartPoints = dexLiquidityResponse.volumePoints
//                let txCountChartPoints = transactionDataResponse.countPoints
//                let txVolumeChartPoints = transactionDataResponse.volumePoints
//                let activeAddresses = activeAddressesResponse.countPoints
//
//                return ProFeatures(
//                        activated: true,
//                        dexVolumes: .value(dexVolumeChartPoints),
//                        dexLiquidity: .value(dexLiquidityChartPoints),
//                        txCount: .value(txCountChartPoints),
//                        txVolume: .value(txVolumeChartPoints),
//                        activeAddresses: .value(activeAddresses)
//                )
//            }
//        } else {
//            return Single.just(ProFeatures.forbidden)
//        }
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
        return currencies.first {
            $0.code == "USD"
        } ?? currencies[0]
    }

    var coin: Coin {
        fullCoin.coin
    }

    var auditAddresses: [String] {
        fullCoin.supportedTokens.compactMap { token in
            switch (token.blockchainType, token.type) {
            case (.ethereum, .eip20(let address)): return address
            case (.binanceSmartChain, .eip20(let address)): return address
            default: return nil
            }
        }
    }

    var hasMajorHolders: Bool {
        for token in fullCoin.supportedTokens {
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
                        proFeatures(coinUid: fullCoin.coin.uid, currencyCode: currency.code))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .flatMap { [weak self] (details, proFeatures) -> Single<Item> in
                    self?.fetchCharts(details: details, proFeatures: proFeatures) ?? Single.just(Item(marketInfoDetails: details, proFeatures: .forbidden, tvls: nil))
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

    enum ProData {
        case empty
        case forbidden
        case completed([ChartPoint])

        static func value(_ points: [ChartPoint]) -> Self {
            points.isEmpty ? .empty : .completed(points)
        }
    }

    struct ProFeatures {
        static var forbidden: ProFeatures {
            ProFeatures(activated: false, dexVolumes: .forbidden, dexLiquidity: .forbidden, txCount: .forbidden, txVolume: .forbidden, activeAddresses: .forbidden)
        }

        static var empty: ProFeatures {
            ProFeatures(activated: true, dexVolumes: .empty, dexLiquidity: .empty, txCount: .empty, txVolume: .empty, activeAddresses: .empty)
        }

        let activated: Bool
        let dexVolumes: ProData
        let dexLiquidity: ProData
        let txCount: ProData
        let txVolume: ProData
        let activeAddresses: ProData
    }

    struct Item {
        let marketInfoDetails: MarketInfoDetails
        let proFeatures: ProFeatures
        let tvls: [ChartPoint]?
    }

}
