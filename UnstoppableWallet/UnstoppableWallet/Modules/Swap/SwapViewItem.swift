import UIKit

enum SwapPath {
    case to
    case from

    var toggle: SwapPath {
        switch self {
        case .to: return .from
        default: return .to
        }
    }
}

struct SwapViewItem {
    let estimatedField: SwapPath
    let estimatedAmount: String?
    let error: Error?

    let tokenIn: String
    let tokenOut: String?

    let availableBalance: String?

    let minMaxTitle: String
    let minMaxValue: String
    let executionPriceValue: String?
    let priceImpactValue: String
    let priceImpactColor: UIColor

    let swapButtonEnabled: Bool
}
