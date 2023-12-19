import MarketKit
import RxCocoa
import RxRelay

class SendBinanceFeeWarningViewModel {
    private let cautionRelay = BehaviorRelay<TitledCaution?>(value: nil)

    init(adapter: ISendBinanceAdapter, coinCode: String, feeToken: Token) {
        if adapter.fee > adapter.availableBinanceBalance {
            let fee = CoinValue(kind: .token(token: feeToken), value: adapter.fee)
            let feeString = ValueFormatter.instance.formatFull(coinValue: fee) ?? ""
            let text = "send.token.insufficient_fee_alert".localized(coinCode, feeToken.blockchain.name, feeToken.coin.name, feeString)

            cautionRelay.accept(TitledCaution(title: "fee_settings.errors.insufficient_balance".localized, text: text, type: .error))
        }
    }
}

extension SendBinanceFeeWarningViewModel: ITitledCautionViewModel {
    var cautionDriver: Driver<TitledCaution?> {
        cautionRelay.asDriver()
    }
}
