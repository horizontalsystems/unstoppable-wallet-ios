import Foundation
import MarketKit

/// Final quote for a StellarBroker `stellar_broker` execution — there is no pre-built tx to
/// show; the confirmation carries the SESSION PARAMETERS the broadcaster uses to run the
/// interactive WebSocket trade (the broker builds + submits the txs, we sign each one).
/// Network fees are paid per fee-bumped tx during the session, so no upfront fee is shown.
class StellarBrokerFinalQuote: SwapFinalQuote {
    let sessionParams: StellarBrokerSessionClient.Params

    init(
        amountOut: Decimal,
        recipient: String?,
        estimatedTime: TimeInterval?,
        sessionParams: StellarBrokerSessionClient.Params,
        transactionError: Error?,
        toAddress: String,
        providerSwapId: String?
    ) {
        self.sessionParams = sessionParams

        super.init(
            expectedBuyAmount: amountOut,
            // The broker re-quotes live in-session bound by slippageTolerance; nothing
            // client-verifiable enforces a floor, so no "guaranteed" row (nil slippage).
            slippage: nil,
            recipient: recipient,
            estimatedTime: estimatedTime,
            transactionError: transactionError,
            toAddress: toAddress,
            depositAddress: nil,
            providerSwapId: providerSwapId
        )
    }

    override func executable(tokenIn: Token) -> ISwapExecutable {
        StellarExecutable(token: tokenIn, kind: .brokerSession(sessionParams))
    }

    override func caution(transactionError: Error, baseToken: Token) -> CautionNew? {
        StellarSendHelper.caution(transactionError: transactionError, feeToken: baseToken)
    }
}
