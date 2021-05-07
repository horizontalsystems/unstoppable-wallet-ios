import Foundation
import CurrencyKit
import RxSwift
import CoinKit

class SendFeeInteractor {
    private let rateManager: IRateManager
    private let currencyKit: CurrencyKit.Kit
    private let feeCoinProvider: IFeeCoinProvider

    weak var delegate: ISendFeeInteractorDelegate?

    var disposeBag = DisposeBag()

    init(rateManager: IRateManager, currencyKit: CurrencyKit.Kit, feeCoinProvider: IFeeCoinProvider) {
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
