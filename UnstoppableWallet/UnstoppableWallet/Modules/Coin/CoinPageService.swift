import UIKit
import RxSwift
import RxCocoa
import XRatesKit
import CoinKit
import CurrencyKit

class CoinPageService {
    static let timePeriods: [TimePeriod] = [.day7, .day30]

    private var disposeBag = DisposeBag()

    private let coinKit: CoinKit.Kit
    private let rateManager: IRateManager
    private let currencyKit: ICurrencyKit
    private let appConfigProvider: IAppConfigProvider
    private let coinType: CoinType

    let coinTitle: String
    let coinCode: String

    private let stateRelay = PublishRelay<DataStatus<CoinMarketInfo>>()
    private(set) var state: DataStatus<CoinMarketInfo> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coinKit: CoinKit.Kit, rateManager: IRateManager, currencyKit: ICurrencyKit, appConfigProvider: IAppConfigProvider, coinType: CoinType, coinTitle: String, coinCode: String) {
        self.coinKit = coinKit
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
        var codes = [String]()

        codes.append(currencyKit.baseCurrency.code)
        codes.append(contentsOf: [coinKit.coin(type: .bitcoin), coinKit.coin(type: .ethereum)].compactMap { $0?.code })

        return codes
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
