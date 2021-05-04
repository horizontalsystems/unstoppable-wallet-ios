import UIKit
import RxSwift
import RxCocoa
import XRatesKit
import CoinKit
import CurrencyKit

class CoinPageService {
    private let roiCoinCodes = ["BTC", "ETH", "BNB"]
    static let timePeriods: [TimePeriod] = [.day7, .day30]

    private var disposeBag = DisposeBag()

    private let rateManager: IRateManager
    private let currencyKit: CurrencyKit.Kit
    private let appConfigProvider: IAppConfigProvider

    let coinType: CoinType
    let coinTitle: String
    let coinCode: String

    private let stateRelay = PublishRelay<DataStatus<CoinMarketInfo>>()
    private(set) var state: DataStatus<CoinMarketInfo> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(rateManager: IRateManager, currencyKit: CurrencyKit.Kit, appConfigProvider: IAppConfigProvider, coinType: CoinType, coinTitle: String, coinCode: String) {
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.appConfigProvider = appConfigProvider
        self.coinType = coinType
        self.coinTitle = coinTitle
        self.coinCode = coinCode

        fetchChartData()
    }

    private func fetchChartData() {
        disposeBag = DisposeBag()
        state = .loading

        let coinMarketInfo = rateManager.coinMarketInfoSingle(
                coinType: coinType,
                currencyCode: currencyKit.baseCurrency.code,
                rateDiffTimePeriods: Self.timePeriods,
                rateDiffCoinCodes: diffCoinCodes
        )

        coinMarketInfo
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] coinMarketInfo in
                    self?.state = .completed(coinMarketInfo)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    var diffCoinCodes: [String] {
        let baseCurrencyCode = currencyKit.baseCurrency.code
        return [baseCurrencyCode].filter { $0 != coinCode } + roiCoinCodes.filter { $0 != baseCurrencyCode && $0 != coinCode }
    }

    var guideUrl: URL? {
        guard let guideFileUrl = guideFileUrl else {
            return nil
        }

        return URL(string: guideFileUrl, relativeTo: appConfigProvider.guidesIndexUrl)
    }

    private var guideFileUrl: String? {
        switch coinType {
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
            default: return nil
            }
        default: return nil
        }
    }

}

extension CoinPageService {

    var stateObservable: Observable<DataStatus<CoinMarketInfo>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

}
