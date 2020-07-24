import Foundation

enum SwapPath {
    case to
    case from

    var estimated: SwapPath {
        switch self {
        case .to: return .from
        default: return .to
        }
    }
}

struct SwapViewItem {
    let estimatedField: SwapPath
    let estimatedAmount: String?

    let tokenIn: String
    let tokenOut: String

    let availableBalance: String?

    let minMaxTitle: String
    let minMaxValue: String
    let executionPriceValue: String
    let priceImpactValue: String

    let swapButtonEnabled: Bool
}
