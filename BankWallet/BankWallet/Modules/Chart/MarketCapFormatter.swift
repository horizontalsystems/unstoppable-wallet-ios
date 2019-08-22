import Foundation

class MarketCapFormatter {
    public enum FormatError: Error {
        case lessOne
        case moreTrillions
    }

    private static let postfixes = ["k", "M", "B", "T"]

    static func marketCap(circulatingSupply: Decimal, rate: Decimal) throws -> (value: Decimal, postfix: String?) {
        let fullValue = circulatingSupply * rate
        let ten: Decimal = 10

        var index = 0
        var power: Decimal = 1
        while fullValue >= power {
            index += 1
            power = pow(ten, index * 3)
        }
        switch index {
        case 0: throw FormatError.lessOne
        case 1: return (value: fullValue, postfix: nil)
        case (postfixes.count + 1)...Int.max: throw FormatError.moreTrillions
        default: return (value: fullValue / pow(ten, (index - 1) * 3), postfix: MarketCapFormatter.postfixes[index - 2])
        }
    }

}
