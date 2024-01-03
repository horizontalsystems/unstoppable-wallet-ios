import BigInt
import Foundation

private let max256ByteNumber = BigUInt(Data(hex: "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))

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

    func rounded(decimal: Int) -> Decimal {
        let poweredDecimal = self * pow(10, decimal)
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue / pow(10, decimal)
    }
}
