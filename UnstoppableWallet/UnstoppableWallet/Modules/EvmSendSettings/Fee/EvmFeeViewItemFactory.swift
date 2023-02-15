import Foundation

struct FeeViewItem {
    let initialValue: Float
    let step: Int
    let scale: FeePriceScale
    let range: ClosedRange<Float>

    var description: String {
        scale.description(value: initialValue)
    }
}

class FeeViewItemFactory {
    static let stepDepth = 2
    private let scale: FeePriceScale

    init(scale: FeePriceScale) {
        self.scale = scale
    }
}

extension FeeViewItemFactory {
    func viewItem(value: Int, step: Int, range: ClosedRange<Int>) -> FeeViewItem {
        let floatingRange = ClosedRange<Float>(uncheckedBounds:
            (lower: scale.wrap(value: range.lowerBound, step: step),
             upper: scale.wrap(value: range.upperBound, step: step))
        )

        return FeeViewItem(
            initialValue: scale.wrap(value: value, step: step),
            step: step,
            scale: scale,
            range: floatingRange
        )
    }

    func description(value: Int, step: Int) -> String {
        scale.description(value: scale.wrap(value: value, step: step))
    }

    func decimalValue(value: Int) -> Decimal {
        Decimal(value) / Decimal(scale.scaleValue)
    }

    func intValue(value: Decimal) -> Int {
        NSDecimalNumber(decimal: value * Decimal(scale.scaleValue)).intValue
    }

    func intValue(value: Float) -> Int {
        Int(value * Float(scale.scaleValue))
    }

}
