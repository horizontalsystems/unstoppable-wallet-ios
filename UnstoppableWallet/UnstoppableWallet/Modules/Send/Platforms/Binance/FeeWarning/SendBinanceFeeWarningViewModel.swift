import MarketKit
import RxRelay
import RxCocoa

class SendBinanceFeeWarningViewModel {

    private let cautionRelay = BehaviorRelay<TitledCaution?>(value: nil)

    init(adapter: ISendBinanceAdapter, coinCode: String, tokenProtocol: String?, feeToken: Token) {
        guard let tokenProtocol = tokenProtocol else {
            return
        }

        if adapter.fee > adapter.availableBinanceBalance {
            let fee = CoinValue(kind: .token(token: feeToken), value: adapter.fee)
            let feeString = ValueFormatter.instance.formatFull(coinValue: fee) ?? ""
            let text = "send.token.insufficient_fee_alert".localized(coinCode, tokenProtocol, feeToken.coin.name, feeString)

            cautionRelay.accept(TitledCaution(title: "fee_settings.errors.insufficient_balance".localized, text: text, type: .error))
        }
    }

}

extension SendBinanceFeeWarningViewModel: ITitledCautionViewModel {

    var cautionDriver: Driver<TitledCaution?> {
        cautionRelay.asDriver()
    }

}
