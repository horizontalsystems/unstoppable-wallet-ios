import Foundation
import CurrencyKit
import RxSwift
import CoinKit

class SendFeeInteractor {
    private let rateManager: IRateManager
    private let currencyKit: ICurrencyKit
    private let feeCoinProvider: IFeeCoinProvider

    weak var delegate: ISendFeeInteractorDelegate?

    var disposeBag = DisposeBag()

    init(rateManager: IRateManager, currencyKit: ICurrencyKit, feeCoinProvider: IFeeCoinProvider) {
        self.rateManager = rateManager
        self.currencyKit = currencyKit
        self.feeCoinProvider = feeCoinProvider
    }

}

extension SendFeeInteractor: ISendFeeInteractor {

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

    func feeCoin(coin: Coin) -> Coin? {
        feeCoinProvider.feeCoin(coin: coin)
    }

    func feeCoinProtocol(coin: Coin) -> String? {
        feeCoinProvider.feeCoinProtocol(coin: coin)
    }

    func subscribeToMarketInfo(coinType: CoinType?, currencyCode: String) {
        guard let coinType = coinType else {
            return
        }

        //todo:
//        rateManager.marketInfoObservable(coinType: coinType, currencyCode: currencyCode)
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { [weak self] marketInfo in
//                    self?.delegate?.didReceive(marketInfo: marketInfo)
//                })
//                .disposed(by: disposeBag)
    }

    func nonExpiredRateValue(coinType: CoinType, currencyCode: String) -> Decimal? {
        nil
        //todo:
//        guard let marketInfo = rateManager.marketInfo(coinType: coinType, currencyCode: currencyCode), !marketInfo.expired else {
//        }
//        return marketInfo.rate
    }

}
