import BitcoinCore
import Foundation
import MarketKit

class UnstoppableMultiSwapBtcConfirmationQuote: BaseSendBtcData, IMultiSwapConfirmationQuote {
    let amountIn: Decimal
    let expectedAmountOut: Decimal
    let amountOutMin: Decimal
    let recipient: Address?
    let slippage: Decimal
    let sendParameters: SendParameters?
    let transactionError: Error?

    init(amountIn: Decimal, expectedAmountOut: Decimal, amountOutMin: Decimal, recipient: Address?, slippage: Decimal, satoshiPerByte: Int?, fee: Decimal?, sendParameters: SendParameters?, transactionError: Error?) {
        self.amountIn = amountIn
        self.expectedAmountOut = expectedAmountOut
        self.amountOutMin = amountOutMin
        self.recipient = recipient
        self.slippage = slippage
        self.sendParameters = sendParameters
        self.transactionError = transactionError

        super.init(satoshiPerByte: satoshiPerByte, fee: fee)
    }

    var amountOut: Decimal {
        expectedAmountOut
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

    func priceSectionFields(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, baseToken _: MarketKit.Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate: Decimal?, baseTokenRate _: Decimal?) -> [SendField] {
        var fields = [SendField]()

        if let recipient {
            fields.append(.recipient(recipient.title, blockchainType: tokenOut.blockchainType))
        }

        fields.append(.slippage(slippage))

        fields.append(
            .value(
                title: "swap.confirmation.minimum_received".localized,
                description: nil,
                appValue: AppValue(token: tokenOut, value: amountOutMin),
                currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: amountOutMin * $0) },
                formatFull: true
            )
        )

        return fields
    }

    func otherSections(tokenIn _: Token, tokenOut _: Token, baseToken: Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, baseTokenRate: Decimal?) -> [SendDataSection] {
        var sections = [SendDataSection]()

        let feeFields = super.feeFields(feeToken: baseToken, currency: currency, feeTokenRate: baseTokenRate)

        if !feeFields.isEmpty {
            sections.append(.init(feeFields))
        }

        return sections
    }
}
