import Foundation
import MarketKit

public protocol ISplitSwapProvider: IMultiSwapProvider {
    func splitQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, percents: [Int]) async throws -> SplitMultiSwapQuote
    func splitConfirmationQuote(quote: SplitMultiSwapQuote, tokenIn: Token, tokenOut: Token, amountIn: Decimal, recipients: [SplitRecipient], transactionSettings: TransactionSettings?) async throws -> SwapFinalQuote
}
