import Foundation
import MarketKit

class BaseSendBtcData {
    let satoshiPerByte: Int?
    let bytes: Int?

    init(satoshiPerByte: Int?, bytes: Int?) {
        self.satoshiPerByte = satoshiPerByte
        self.bytes = bytes
    }

    func amountData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        guard let satoshiPerByte, let bytes else {
            return nil
        }

        let amount = Decimal(satoshiPerByte) * Decimal(bytes) / pow(10, feeToken.decimals)

        return AmountData(
            coinValue: CoinValue(kind: .token(token: feeToken), value: amount),
            currencyValue: feeTokenRate.map { CurrencyValue(currency: currency, value: amount * $0) }
        )
    }

    func feeFields(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> [SendConfirmField] {
        let amountData = amountData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate)

        return [
            .value(
                title: "fee_settings.network_fee".localized,
                description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                coinValue: amountData?.coinValue,
                currencyValue: amountData?.currencyValue,
                formatFull: true
            ),
        ]
    }
}
