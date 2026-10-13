import Foundation
import MarketKit

public protocol ISplitSwapProvider: IMultiSwapProvider {
    func splitQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, percents: [Int]) async throws -> SplitMultiSwapQuote
    // No side effects: the split route for the confirmation screen, its fee estimated against the stub deposit
    func splitPreview(tokenIn: Token, tokenOut: Token, amountIn: Decimal, recipients: [SplitRecipient], slippage: Decimal, transactionSettings: TransactionSettings?) async throws -> SplitSwapPreview
    // Creates the order for a previewed split and rebuilds the transfer against the real deposit.
    // The preview's token is consumed whatever the outcome.
    func splitCommit(finalQuote: SwapFinalQuote) async throws -> SplitSwapCommitment
    func reportSplitInboundTxHash(splitUuid: String, txHash: String) async throws
}
