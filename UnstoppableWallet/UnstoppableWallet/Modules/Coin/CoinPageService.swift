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
    private let currentLocale: String

    let fullCoin: FullCoin

    private let stateRelay = PublishRelay<DataStatus<MarketInfoOverview>>()
    private(set) var state: DataStatus<MarketInfoOverview> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, appConfigProvider: IAppConfigProvider, currentLocale: String, fullCoin: FullCoin) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.appConfigProvider = appConfigProvider
        self.currentLocale = currentLocale
        self.fullCoin = fullCoin

        fetchChartData()
    }

    private func fetchChartData() {
        disposeBag = DisposeBag()
        state = .loading

        marketKit.marketInfoOverviewSingle(coinUid: fullCoin.coin.uid, currencyCode: currencyKit.baseCurrency.code, languageCode: currentLocale)
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
        switch fullCoin.coin.uid {
        case "bitcoin": return "guides/token_guides/en/bitcoin.md"
        case "ethereum": return "guides/token_guides/en/ethereum.md"
        case "bitcoin-cash": return "guides/token_guides/en/bitcoin-cash.md"
        case "zcash": return "guides/token_guides/en/zcash.md"
        case "uniswap": return "guides/token_guides/en/uniswap.md"
        case "curve-dao-token": return "guides/token_guides/en/curve-finance.md"
        case "balancer": return "guides/token_guides/en/balancer-dex.md"
        case "synthetix-network-token": return "guides/token_guides/en/synthetix.md"
        case "tether": return "guides/token_guides/en/tether.md"
        case "maker": return "guides/token_guides/en/makerdao.md"
        case "dai": return "guides/token_guides/en/makerdao.md"
        case "aave": return "guides/token_guides/en/aave.md"
        case "compound": return "guides/token_guides/en/compound.md"
        default: return nil
        }
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
