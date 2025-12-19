import EvmKit
import Foundation
import MarketKit
import OneInchKit

class OneInchMultiSwapConfirmationQuote: BaseEvmMultiSwapConfirmationQuote {
    let swap: Swap
    let recipient: Address?
    let slippage: Decimal
    let insufficientFeeBalance: Bool

    init(swap: Swap, recipient: Address?, slippage: Decimal, insufficientFeeBalance: Bool, evmFeeData: EvmFeeData, nonce: Int?) {
        self.swap = swap
        self.recipient = recipient
        self.slippage = slippage
        self.insufficientFeeBalance = insufficientFeeBalance

        super.init(gasPrice: swap.transaction.gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    override var amountOut: Decimal {
        swap.amountOut ?? 0
    }

    override var canSwap: Bool {
        super.canSwap && !insufficientFeeBalance
    }

    override func cautions(baseToken: MarketKit.Token) -> [CautionNew] {
        var cautions = super.cautions(baseToken: baseToken)

        if insufficientFeeBalance {
            cautions.append(
                .init(
                    title: "fee_settings.errors.insufficient_balance".localized,
                    text: "ethereum_transaction.error.insufficient_balance_with_fee".localized(baseToken.coin.code),
                    type: .error
                )
            )
        }

        return cautions
    }

    override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, baseToken: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = [SendField]()

        let minAmountOut = amountOut * (1 - slippage / 100)
        if let minRecieve = SendField.minRecieve(token: tokenOut, value: minAmountOut) {
            fields.append(minRecieve)
        }

        if let slippage = SendField.slippage(slippage) {
            fields.append(slippage)
        }

        if let recipient {
            fields.append(.recipient(recipient.title, blockchainType: tokenOut.blockchainType))
        }

        return fields + super.fields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)
    }
}
