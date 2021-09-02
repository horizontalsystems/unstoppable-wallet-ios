import Foundation
import CurrencyKit
import RxSwift
import MarketKit

class SendFeeInteractor {
    private let rateManager: RateManagerNew
    private let currencyKit: CurrencyKit.Kit
    private let feeCoinProvider: FeeCoinProvider

    weak var delegate: ISendFeeInteractorDelegate?

    var disposeBag = DisposeBag()

    init(rateManager: RateManagerNew, currencyKit: CurrencyKit.Kit, feeCoinProvider: FeeCoinProvider) {
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.feeCoinProvider = feeCoinProvider
    }

}

extension SendFeeInteractor: ISendFeeInteractor {

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    func feeCoin(platformCoin: PlatformCoin) -> PlatformCoin? {
        feeCoinProvider.feeCoin(coinType: platformCoin.coinType)
    }

    func feeCoinProtocol(platformCoin: PlatformCoin) -> String? {
        feeCoinProvider.feeCoinProtocol(coinType: platformCoin.coinType)
    }

    func subscribeToLatestRate(coinType: CoinType?, currencyCode: String) {
        guard let coinType = coinType else {
            return
        }

        rateManager.latestRateObservable(coinType: coinType, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] latestRate in
                    self?.delegate?.didReceive(latestRate: latestRate)
                })
                .disposed(by: disposeBag)
    }

    func nonExpiredRateValue(coinType: CoinType, currencyCode: String) -> Decimal? {
        guard let latestRate = rateManager.latestRate(coinType: coinType, currencyCode: currencyCode), !latestRate.expired else {
            return nil
        }

        return latestRate.rate
    }

}
