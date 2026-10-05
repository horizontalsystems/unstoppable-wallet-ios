import Foundation

class FeeViewItemFactory {
    static let stepDepth = 2
    private let scale: FeePriceScale

    init(scale: FeePriceScale) {
        self.scale = scale
    }
}

extension FeeViewItemFactory {
    func decimalValue(value: Int) -> Decimal {
        Decimal(value) / Decimal(scale.scaleValue)
    }

    func intValue(value: Decimal) -> Int {
        NSDecimalNumber(decimal: value * Decimal(scale.scaleValue)).intValue
    }

    func updated(value: Decimal, percent: Decimal, direction: StepChangeButtonsViewDirection) -> Decimal {
        let diff = value * percent / 100
        let result: Decimal

        switch direction {
        case .down: result = max(value - diff, 0)
        case .up: result = value + diff
        }

        return result.rounded(decimal: scale.scaleDecimals)
    }
}
