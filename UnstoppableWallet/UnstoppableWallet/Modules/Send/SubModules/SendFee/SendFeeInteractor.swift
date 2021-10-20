import Foundation
import CurrencyKit
import RxSwift
import MarketKit

class SendFeeInteractor {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let feeCoinProvider: FeeCoinProvider

    weak var delegate: ISendFeeInteractorDelegate?

    var disposeBag = DisposeBag()

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, feeCoinProvider: FeeCoinProvider) {
        self.marketKit = marketKit
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

    func subscribeToCoinPrice(coinUid: String?, currencyCode: String) {
        guard let coinUid = coinUid else {
            return
        }

        marketKit.coinPriceObservable(coinUid: coinUid, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] coinPrice in
                    self?.delegate?.didReceive(coinPrice: coinPrice)
                })
                .disposed(by: disposeBag)
    }

    func nonExpiredRateValue(coinUid: String, currencyCode: String) -> Decimal? {
        guard let coinPrice = marketKit.coinPrice(coinUid: coinUid, currencyCode: currencyCode), !coinPrice.expired else {
            return nil
        }

        return coinPrice.value
    }

}
