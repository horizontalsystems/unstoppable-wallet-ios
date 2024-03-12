import BigInt
import EvmKit
import Foundation
import MarketKit

struct EvmFeeData {
    let gasLimit: Int
    let l1Fee: BigUInt?

    init(gasLimit: Int, l1Fee: BigUInt? = nil) {
        self.gasLimit = gasLimit
        self.l1Fee = l1Fee
    }

    func l1FeeValue(feeToken: Token) -> Decimal? {
        guard let l1Fee else {
            return nil
        }

        return Decimal(bigUInt: l1Fee, decimals: feeToken.decimals)
    }

    func feeAmountData(gasPrice: GasPrice?, feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
        guard let gasPrice else {
            return nil
        }

        var amount = Decimal(gasLimit) * Decimal(gasPrice.max) / pow(10, feeToken.decimals)

        if let l1FeeValue = l1FeeValue(feeToken: feeToken) {
            amount += l1FeeValue
        }

        let coinValue = CoinValue(kind: .token(token: feeToken), value: amount)
        let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: amount * $0) }

        return AmountData(coinValue: coinValue, currencyValue: currencyValue)
    }
}
