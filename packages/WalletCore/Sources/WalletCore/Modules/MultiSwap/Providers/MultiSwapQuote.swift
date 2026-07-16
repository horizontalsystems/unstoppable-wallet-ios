import Foundation

public class MultiSwapQuote {
    public let expectedBuyAmount: Decimal
    public let estimatedTime: TimeInterval?

    public init(expectedBuyAmount: Decimal, estimatedTime: TimeInterval? = nil) {
        self.expectedBuyAmount = expectedBuyAmount
        self.estimatedTime = estimatedTime
    }

    var customButtonState: MultiSwapButtonState? {
        nil
    }

    func cautions() -> [CautionNew] {
        []
    }
}
