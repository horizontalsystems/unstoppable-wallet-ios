import Foundation
import BigInt

fileprivate let max256ByteNumber = BigUInt(Data(hex: "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))

extension Decimal {

    init?(bigUInt: BigUInt, decimals: Int) {
        guard let significand = Decimal(string: bigUInt.description) else {
            return nil
        }

        self.init(sign: .plus, exponent: -decimals, significand: significand)
    }

    var decimalCount: Int {
        max(-exponent, 0)
    }

    func significandDigits(fractionDigits: Int) -> Int {
        let integerDigits = significand.description.count + exponent
        return integerDigits + fractionDigits
    }

    func isMaxValue(decimals: Int) -> Bool {
        let maxInDecimal = Decimal(sign: .plus, exponent: -decimals, significand: Decimal(string: max256ByteNumber.description)!)
        return maxInDecimal == self
    }

}
