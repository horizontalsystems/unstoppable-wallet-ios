import BitcoinCore
import Foundation
import MarketKit

class BaseSendBtcData {
    let satoshiPerByte: Int?
    let fee: Decimal?

    init(satoshiPerByte: Int?, fee: Decimal?) {
        self.satoshiPerByte = satoshiPerByte
        self.fee = fee
    }

    func amountData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        guard let fee else {
            return nil
        }

        return AmountData(
            appValue: AppValue(token: feeToken, value: fee),
            currencyValue: feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }
        )
    }

    func feeFields(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> [SendField] {
        let amountData = amountData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate)

        return [
            .value(
                title: "fee_settings.network_fee".localized,
                description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                appValue: amountData?.appValue,
                currencyValue: amountData?.currencyValue,
                formatFull: true
            ),
        ]
    }

    func caution(transactionError: Error, feeToken: Token) -> CautionNew {
        let title: String
        let text: String

        if let error = transactionError as? BitcoinCoreErrors.SendValueErrors {
            switch error {
            case .notEnough:
                title = "fee_settings.errors.insufficient_balance".localized
                text = "fee_settings.errors.insufficient_balance.info".localized(feeToken.coin.code)

            case .dust(let dustAmount):
                title = "send.amount_error.minimum_amount.title".localized
                text = "send.amount_error.minimum_amount.description".localized("\(dustAmount) satoshis")

            default:
                title = "Send Info error"
                text = "Send Info error description"
            }
        } else {
            title = "alert.error".localized
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }
}
