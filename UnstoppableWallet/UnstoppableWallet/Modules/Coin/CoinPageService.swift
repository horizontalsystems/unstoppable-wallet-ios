import UIKit
import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit

class CoinPageService {
    private var disposeBag = DisposeBag()

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let appConfigProvider: IAppConfigProvider

    let fullCoin: FullCoin

    private let stateRelay = PublishRelay<DataStatus<MarketInfoOverview>>()
    private(set) var state: DataStatus<MarketInfoOverview> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, appConfigProvider: IAppConfigProvider, fullCoin: FullCoin) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.appConfigProvider = appConfigProvider
        self.fullCoin = fullCoin

        fetchChartData()
    }

    private func fetchChartData() {
        disposeBag = DisposeBag()
        state = .loading

        marketKit.marketInfoOverviewSingle(coinUid: fullCoin.coin.uid, currencyCode: currencyKit.baseCurrency.code, languageCode: Locale.current.languageCode ?? "en")
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] info in
                    self?.state = .completed(info)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    var guideUrl: URL? {
        guard let guideFileUrl = guideFileUrl else {
            return nil
        }

        return URL(string: guideFileUrl, relativeTo: appConfigProvider.guidesIndexUrl)
    }

    private var guideFileUrl: String? {
        for platform in fullCoin.platforms {
            switch platform.coinType {
                case .bitcoin: return "guides/token_guides/en/bitcoin.md"
                case .ethereum: return "guides/token_guides/en/ethereum.md"
                case .bitcoinCash: return "guides/token_guides/en/bitcoin-cash.md"
                case .zcash: return "guides/token_guides/en/zcash.md"
                case .erc20(let address):
                    switch address {
                        case "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984": return "guides/token_guides/en/uniswap.md"
                        case "0xd533a949740bb3306d119cc777fa900ba034cd52": return "guides/token_guides/en/curve-finance.md"
                        case "0xba100000625a3754423978a60c9317c58a424e3d": return "guides/token_guides/en/balancer-dex.md"
                        case "0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f": return "guides/token_guides/en/synthetix.md"
                        case "0xdac17f958d2ee523a2206206994597c13d831ec7": return "guides/token_guides/en/tether.md"
                        case "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2": return "guides/token_guides/en/makerdao.md"
                        case "0x6b175474e89094c44da98b954eedeac495271d0f": return "guides/token_guides/en/makerdao.md"
                        case "0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9": return "guides/token_guides/en/aave.md"
                        case "0xc00e94cb662c3520282e6f5717214004a7f26888": return "guides/token_guides/en/compound.md"
                        default: ()
                    }
                default: ()
            }
        }
        
        return nil
    }

}

extension CoinPageService {

    var stateObservable: Observable<DataStatus<MarketInfoOverview>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

}
