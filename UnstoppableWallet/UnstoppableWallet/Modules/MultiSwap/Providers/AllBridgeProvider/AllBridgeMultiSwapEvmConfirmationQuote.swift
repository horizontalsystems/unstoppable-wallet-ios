//
//  AllBridgeMultiSwapEvmConfirmationQuote.swift
//  UnstoppableWallet
//
//  Created by Anton Stavnichiy on 11/8/25.
//  Copyright © 2025 Horizontal Systems. All rights reserved.
//

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
    let transactionError: Error?

    init(amountIn: Decimal, expectedAmountOut: Decimal, recipient: Address?, crosschain: Bool, slippage: Decimal, transactionData: TransactionData, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
        self.amountIn = amountIn
        self.expectedAmountOut = expectedAmountOut
        self.recipient = recipient
        self.crosschain = crosschain
        self.slippage = slippage
        self.transactionData = transactionData
        self.transactionError = transactionError

        super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
    }

    override var amountOut: Decimal {
        expectedAmountOut
    }

    override func cautions(baseToken: MarketKit.Token) -> [CautionNew] {
        var cautions = super.cautions(baseToken: baseToken)

        if let transactionError {
            cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
        }

        if crosschain {
            cautions.append(CautionNew(title: "swap.allbridge.slip_protection".localized, text: "swap.allbridge.slip_protection.description", type: .warning))
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

        return fields
    }

    override func otherSections(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendDataSection] {
        var sections = super.otherSections(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        return sections
    }

    override func additionalFeeFields(tokenIn: Token, tokenOut: Token, baseToken: Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, baseTokenRate: Decimal?) -> [SendField] {
        var fields = super.additionalFeeFields(tokenIn: tokenIn, tokenOut: tokenOut, baseToken: baseToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, baseTokenRate: baseTokenRate)

        return fields
    }
}
