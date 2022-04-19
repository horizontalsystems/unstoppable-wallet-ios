import MarketKit
import RxRelay
import RxCocoa

class SendXBinanceFeeWarningViewModel {

    private let cautionRelay = BehaviorRelay<TitledCaution?>(value: nil)

    init(adapter: ISendBinanceAdapter, coinCode: String, coinProtocol: String?, feeCoin: PlatformCoin) {
        guard let coinProtocol = coinProtocol else {
            return
        }

        if adapter.fee > adapter.availableBinanceBalance {
            let fee = CoinValue(kind: .platformCoin(platformCoin: feeCoin), value: adapter.fee)
            let text = "send.token.insufficient_fee_alert".localized(coinCode, coinProtocol, feeCoin.name, fee.formattedString ?? "")

            cautionRelay.accept(TitledCaution(title: "fee_settings.errors.insufficient_balance".localized, text: text, type: .error))
        }
    }

}

extension SendXBinanceFeeWarningViewModel: ITitledCautionViewModel {

    var cautionDriver: Driver<TitledCaution?> {
        cautionRelay.asDriver()
    }

}
