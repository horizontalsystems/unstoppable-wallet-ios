import Foundation

extension Decimal {
    var decimalCount: Int {
        return max(-exponent, 0)
    }
}
