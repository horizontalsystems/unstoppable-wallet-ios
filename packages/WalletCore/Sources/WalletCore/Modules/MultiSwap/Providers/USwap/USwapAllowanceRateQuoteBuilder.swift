import Foundation
import HsToolKit
import MarketKit
import SwiftUI

final class USwapAllowanceRateQuoteBuilder: USwapRateQuoteBuilder {
    private let allowanceHelper: MultiSwapAllowanceHelper

    init(allowanceHelper: MultiSwapAllowanceHelper) {
        self.allowanceHelper = allowanceHelper
    }

    func supports(tokenIn: Token) -> Bool {
        tokenIn.blockchainType.isEvm || tokenIn.blockchainType == .tron
    }

    func build(input: USwapRateQuoteFactory.Input) async throws -> MultiSwapQuote {
        var allowanceState: MultiSwapAllowanceHelper.AllowanceState = .notRequired

        if let approvalAddress = input.response.approvalSpender {
            allowanceState = await allowanceHelper.allowanceState(
                spenderAddress: .init(raw: approvalAddress),
                token: input.tokenIn,
                amount: input.amountIn
            )
        }

        let estimatedTime = input.response.estimatedTime
            ?? MultiSwapHelpers.estimate(tokenIn: input.tokenIn, tokenOut: input.tokenOut)

        return USwapEvmMultiSwapQuote(
            expectedBuyAmount: input.response.expectedBuyAmount,
            allowanceState: allowanceState,
            estimatedTime: estimatedTime,
            replay: input.replay
        )
    }

    func preSwapView(
        step: MultiSwapPreSwapStep,
        tokenIn: Token,
        amount: Decimal,
        isPresented: Binding<Bool>,
        onSuccess: @escaping () -> Void
    ) -> AnyView? {
        allowanceHelper.preSwapView(
            step: step,
            tokenIn: tokenIn,
            amount: amount,
            isPresented: isPresented,
            onSuccess: onSuccess
        )
    }
}
