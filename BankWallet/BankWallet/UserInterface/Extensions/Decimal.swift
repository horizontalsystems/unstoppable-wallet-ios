import Foundation

extension Decimal {

    var decimalCount: Int {
        max(-exponent, 0)
    }

    func significantDecimalCount(threshold: Int, maxDecimals: Int) -> Int {
        let thresholdRange = pow(10, threshold - 1)

        for decimalCount in 0..<maxDecimals {
            if self * pow(10, decimalCount) >= thresholdRange {
                return decimalCount
            }
        }
        return maxDecimals
    }

}
