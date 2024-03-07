import EvmKit
import Foundation
import MarketKit

enum FeeSettings {
    static func feeAmount(feeToken: Token, currency: Currency, feeTokenRate: Decimal?, loading: Bool, gasLimit: Int?, gasPrice: GasPrice?) -> (String?, String?) {
        guard !loading else {
            return (nil, nil)
        }

        guard let gasLimit, let gasPrice else {
            return ("n/a".localized, "n/a".localized)
        }

        let amount = Decimal(gasLimit) * Decimal(gasPrice.max) / pow(10, feeToken.decimals)
        let coinValue = CoinValue(kind: .token(token: feeToken), value: amount)
        let coinValueString = ValueFormatter.instance.formatShort(coinValue: coinValue)

        guard let feeTokenRate else {
            return (coinValueString, "n/a".localized)
        }

        let currencyValue = CurrencyValue(currency: currency, value: amount * feeTokenRate)
        let currencyValueString = ValueFormatter.instance.formatShort(currencyValue: currencyValue)

        return (coinValueString, currencyValueString)
    }

    struct ViewItem {
        let title: String
        let value: String?
        let subValue: String?
    }
}
