import Foundation

public struct SplitRecipient {
    public let address: String
    public let percent: Int

    public init(address: String, percent: Int) {
        self.address = address
        self.percent = percent
    }
}

enum SplitSwapError: Error {
    case notSupported
    case invalidPercents
    case invalidRoute
}

// A split swap quote: one output token delivered to several addresses. `expectedBuyAmount` is the
// sum of the outputs, so the standard quote sorting and the output box work unchanged.
public final class SplitMultiSwapQuote: MultiSwapQuote {
    public let percents: [Int]
    public let outputAmounts: [Decimal]
    public let guaranteedAmountOut: Decimal?

    init(percents: [Int], outputAmounts: [Decimal], guaranteedAmountOut: Decimal?, estimatedTime: TimeInterval?) {
        self.percents = percents
        self.outputAmounts = outputAmounts
        self.guaranteedAmountOut = guaranteedAmountOut

        super.init(expectedBuyAmount: outputAmounts.reduce(0, +), estimatedTime: estimatedTime)
    }
}

// The previewed split: the quote of the one deposit transfer, and each output's expected amount in recipient order
public struct SplitSwapPreview {
    public let quote: SwapFinalQuote
    public let outputAmounts: [Decimal]
}

// A created split order: the transfer to send (its amount out is the committed total) and the
// `splitUuid` the split is tracked by as a whole
public struct SplitSwapCommitment {
    public let quote: SwapFinalQuote
    public let splitUuid: String
}
