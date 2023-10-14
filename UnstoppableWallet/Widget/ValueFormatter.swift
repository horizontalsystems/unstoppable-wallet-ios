import Foundation

enum ValueFormatter {
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static func fractionZeroCount(value: Decimal, maxCount: Int) -> Int {
        guard value > 0 && value < 1 else {
            return 0
        }

        for count in 0 ..< maxCount {
            if value * pow(10, count + 1) >= 1 {
                return count
            }
        }

        return maxCount
    }

    private static func transformedFull(value: Decimal, maxDigits: Int, minDigits: Int = 0) -> (value: Decimal, digits: Int) {
        let value = abs(value)
        let digits: Int

        switch value {
        case 0:
            digits = 0

        case 0 ..< 1:
            let zeroCount = fractionZeroCount(value: value, maxCount: maxDigits - 1)
            digits = min(maxDigits, zeroCount + 4)

        case 1 ..< 1.01:
            digits = 4

        case 1.01 ..< 1.1:
            digits = 3

        case 1.1 ..< 20:
            digits = 2

        case 20 ..< 200:
            digits = 1

        default:
            digits = 0
        }

        return (value: value, digits: max(digits, minDigits))
    }

    private static func decorated(string: String, symbol: String? = nil, signValue: Decimal? = nil) -> String {
        var string = string

        if let symbol = symbol {
            string = "\(string) \(symbol)"
        }

        if let signValue = signValue {
            var sign = ""
            if !signValue.isZero {
                sign = signValue.isSignMinus ? "-" : "+"
            }
            string = "\(sign)\(string)"
        }

        return string
    }

    static func format(percentValue: Decimal, showSign: Bool = true) -> String? {
        let (transformedValue, digits) = transformedFull(value: percentValue, maxDigits: 2)

        percentFormatter.maximumFractionDigits = digits

        guard let string = percentFormatter.string(from: transformedValue as NSDecimalNumber) else {
            return nil
        }

        return decorated(string: string, signValue: showSign ? percentValue : nil) + "%"
    }
}
