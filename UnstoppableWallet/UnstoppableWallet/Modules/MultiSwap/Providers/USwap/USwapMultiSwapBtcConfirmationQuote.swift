import BitcoinCore
import Foundation
import MarketKit

class USwapMultiSwapBtcConfirmationQuote: BaseSendBtcData, IMultiSwapConfirmationQuote {
    let quote: USwapMultiSwapProvider.Quote
    let recipient: String?
    let slippage: Decimal
    let sendParameters: SendParameters?
    let transactionError: Error?

    init(quote: USwapMultiSwapProvider.Quote, recipient: String?, slippage: Decimal, satoshiPerByte: Int?, fee: Decimal?, sendParameters: SendParameters?, transactionError: Error?) {
        self.quote = quote
        self.recipient = recipient
        self.slippage = slippage
        self.sendParameters = sendParameters
        self.transactionError = transactionError

        super.init(satoshiPerByte: satoshiPerByte, fee: fee)
    }

    var amountOut: Decimal {
        quote.expectedBuyAmount
    }

    var feeData: FeeData? {
        fee.map { .bitcoin(bitcoinFeeData: BitcoinFeeData(fee: $0)) }
    }

    var canSwap: Bool {
        satoshiPerByte != nil && fee != nil
    }

    func cautions(baseToken: MarketKit.Token) -> [CautionNew] {
        transactionError.map { error in
            [caution(transactionError: error, feeToken: baseToken)]
        } ?? []
    }

    func fields(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, baseToken: MarketKit.Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = [SendField]()

        let minAmountOut = amountOut * (1 - slippage / 100)
        if let minRecieve = SendField.minRecieve(token: tokenOut, value: minAmountOut) {
            fields.append(minRecieve)
        }

        if let slippage = SendField.slippage(slippage) {
            fields.append(slippage)
        }

        if let recipient {
            fields.append(.recipient(recipient, blockchainType: tokenOut.blockchainType))
        }

        fields.append(contentsOf: feeFields(feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate))

        return fields
    }
}
