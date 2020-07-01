import Foundation
import CurrencyKit
import RxSwift

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

    func subscribeToMarketInfo(coinCode: CoinCode?, currencyCode: String) {
        guard let coinCode = coinCode else {
            return
        }

        rateManager.marketInfoObservable(coinCode: coinCode, currencyCode: currencyCode)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] marketInfo in
                    self?.delegate?.didReceive(marketInfo: marketInfo)
                })
                .disposed(by: disposeBag)
    }

    func nonExpiredRateValue(coinCode: String, currencyCode: String) -> Decimal? {
        guard let marketInfo = rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode), !marketInfo.expired else {
            return nil
        }
        return marketInfo.rate
    }

}
