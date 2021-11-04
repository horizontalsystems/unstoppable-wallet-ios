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
        guard details.tvl != nil else {
            return Single.just(Item(marketInfoDetails: details, tvls: nil, totalVolumeChart: nil))
        }

        return marketKit
                .marketInfoTvlSingle(coinUid: fullCoin.coin.uid, currencyCode: currency.code, timePeriod: .day30)
                .map { tvls -> Item in
                    Item(marketInfoDetails: details, tvls: tvls, totalVolumeChart: nil)
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

    var coin: Coin {
        fullCoin.coin
    }

    var auditAddresses: [String] {
        fullCoin.platforms.compactMap { platform in
            switch platform.coinType {
            case .erc20(let address): return address
            case .bep20(let address): return address
            default: return nil
            }
        }
    }

    var majorHoldersErc20Address: String? {
        for platform in fullCoin.platforms {
            switch platform.coinType {
            case .erc20(let address): return address
            default: ()
            }
        }

        return nil
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
        let totalVolumeChart: ChartItem?

        init(marketInfoDetails: MarketInfoDetails, tvls: [ChartPoint]? = nil, totalVolumeChart: ChartItem? = nil) {
            self.marketInfoDetails = marketInfoDetails
            self.tvls = tvls
            self.totalVolumeChart = totalVolumeChart
        }

    }

}
