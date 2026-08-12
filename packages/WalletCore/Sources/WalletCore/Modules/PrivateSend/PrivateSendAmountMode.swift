import Foundation

// Exact input stays representable end to end, but only exact output is wired to any UI: with the
// private send toggle on, the amount field means "the amount the recipient receives".
public enum PrivateSendAmountMode: Equatable {
    case exactInput(Decimal) // sellAmount
    case exactOutput(Decimal) // buyAmount

    public var enteredAmount: Decimal {
        switch self {
        case let .exactInput(amount), let .exactOutput(amount): return amount
        }
    }

    public var isExactOutput: Bool {
        if case .exactOutput = self { return true }
        return false
    }

    var amountSpec: USwapMultiSwapApi.AmountSpec {
        switch self {
        case let .exactInput(amount): return .sell(amount)
        case let .exactOutput(amount): return .buy(amount)
        }
    }
}
