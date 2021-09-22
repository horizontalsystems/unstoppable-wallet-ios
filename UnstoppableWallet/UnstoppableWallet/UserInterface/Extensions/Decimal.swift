import Foundation
import BigInt

extension Decimal {

    var decimalCount: Int {
        max(-exponent, 0)
    }

    func significantDecimalCount(threshold: Decimal, maxDecimals: Int) -> Int {
        for decimalCount in 0..<maxDecimals {
            if self * pow(10, decimalCount) >= threshold {
                return decimalCount
            }
        }
        return maxDecimals
    }

    init?(bigUInt: BigUInt, decimals: Int) {
        guard let significand = Decimal(string: bigUInt.description) else {
            return nil
        }

        self.init(sign: .plus, exponent: -decimals, significand: significand)
    }

}
