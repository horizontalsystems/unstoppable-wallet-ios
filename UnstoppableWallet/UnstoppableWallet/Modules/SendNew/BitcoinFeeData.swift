import BigInt
import EvmKit
import Foundation
import MarketKit

struct BitcoinFeeData {
    let sendInfo: SendInfo

    init(sendInfo: SendInfo) {
        self.sendInfo = sendInfo
    }

    func amountData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        let amount = sendInfo.fee

        let coinValue = CoinValue(kind: .token(token: feeToken), value: amount)
        let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: amount * $0) }

        return AmountData(coinValue: coinValue, currencyValue: currencyValue)
    }
}
