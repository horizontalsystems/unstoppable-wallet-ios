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
    case noDepositAddress
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
