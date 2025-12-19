import EvmKit
import Foundation
import MarketKit

class BaseUniswapMultiSwapConfirmationQuote: BaseEvmMultiSwapConfirmationQuote {
    let quote: BaseUniswapMultiSwapQuote
    let transactionData: TransactionData?
    let transactionError: Error?

    init(quote: BaseUniswapMultiSwapQuote, transactionData: TransactionData?, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
        self.quote = quote
        self.transactionData = transactionData
        self.transactionError = transactionError

        super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    override var amountOut: Decimal {
        quote.trade.amountOut ?? 0
    }

    override var canSwap: Bool {
        super.canSwap && transactionData != nil
    }

    override func cautions(baseToken: MarketKit.Token) -> [CautionNew] {
        var cautions = super.cautions(baseToken: baseToken)

        if let transactionError {
            cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
        }

        cautions.append(contentsOf: quote.cautions())

        return cautions
    }

    override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, baseToken: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = [SendField]()

        let slippage = quote.tradeOptions.allowedSlippage

        let minAmountOut = amountOut * (1 - slippage / 100)
        if let minRecieve = SendField.minRecieve(token: tokenOut, value: minAmountOut) {
            fields.append(minRecieve)
        }

        if let slippage = SendField.slippage(slippage) {
            fields.append(slippage)
        }

        if let recipient = quote.recipient {
            fields.append(.recipient(recipient.title, blockchainType: tokenOut.blockchainType))
        }

        return fields + super.fields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)
    }
}
