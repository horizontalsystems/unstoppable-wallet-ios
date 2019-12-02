import UIKit

class ValueScaleHelper: IValueScaleHelper {
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private let digitDiff: Int
    private let maxScale: Int

    init(valueDigitDiff: Int = 5, maxScale: Int = 8) {
        self.digitDiff = valueDigitDiff
        self.maxScale = maxScale
    }

    func scale(min: Decimal, max: Decimal) -> Int {
        let maxIntegerDigits = max.integerDigitCount
        var min = min / pow(10, maxIntegerDigits), max = max / pow(10, maxIntegerDigits)
        var count = -maxIntegerDigits
        while count < maxScale {
            if Int(truncating: (max - min) as NSNumber) >= digitDiff {
                return count + (count == 0 && max < 10 ? 1 : 0)
            } else {
                count += 1
                min *= 10
                max *= 10
            }
        }
        return maxScale
    }

}
