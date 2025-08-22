import EvmKit
import Foundation
import MarketKit

class AllBridgeMultiSwapEvmConfirmationQuote: BaseEvmMultiSwapConfirmationQuote {
    let amountIn: Decimal
    let expectedAmountOut: Decimal
    let recipient: Address?
    let crosschain: Bool
    let slippage: Decimal
    let transactionData: TransactionData
    let insufficientFeeBalance: Bool
    let transactionError: Error?

    init(amountIn: Decimal, expectedAmountOut: Decimal, recipient: Address?, crosschain: Bool, slippage: Decimal, transactionData: TransactionData, insufficientFeeBalance: Bool, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
        self.amountIn = amountIn
        self.expectedAmountOut = expectedAmountOut
        self.recipient = recipient
        self.crosschain = crosschain
        self.slippage = slippage
        self.transactionData = transactionData
        self.insufficientFeeBalance = insufficientFeeBalance
        self.transactionError = transactionError

        super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    override var amountOut: Decimal {
        expectedAmountOut
    }

    override var canSwap: Bool {
        super.canSwap && !insufficientFeeBalance
    }

    override func cautions(baseToken: MarketKit.Token) -> [CautionNew] {
        var cautions = super.cautions(baseToken: baseToken)

        if let transactionError {
            return [caution(transactionError: transactionError, feeToken: baseToken)]
        }

        if insufficientFeeBalance {
            return [
                .init(
                    title: "fee_settings.errors.insufficient_balance".localized,
                    text: "ethereum_transaction.error.insufficient_balance_with_fee".localized(baseToken.coin.code),
                    type: .error
                ),
            ]
        }

        if crosschain {
            cautions.append(.init(
                title: "swap.allbridge.slip_protection".localized,
                text: "swap.allbridge.slip_protection.description".localized,
                type: .warning
            )
            )
        }

        return cautions
    }

    override func priceSectionFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, baseToken: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.priceSectionFields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        if let recipient {
            fields.append(.recipient(recipient.title, blockchainType: tokenOut.blockchainType))
        }

        if slippage != MultiSwapSlippage.default {
            fields.append(.slippage(slippage))
        }

        let minAmountOut = amountOut * (1 - slippage / 100)

        fields.append(
            .value(
                title: "swap.confirmation.minimum_received".localized,
                description: nil,
                appValue: AppValue(token: tokenOut, value: minAmountOut),
                currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: minAmountOut * $0) },
                formatFull: true
            )
        )

        return fields
    }

    override func otherSections(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendDataSection] {
        let sections = super.otherSections(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        return sections
    }

    override func additionalFeeFields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        let fields = super.additionalFeeFields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        return fields
    }
}
