import Foundation

class MarketCapFormatter {
    public enum FormatError: Error {
        case isNull
        case lessOne
        case moreTrillions
    }

    private static let postfixes = ["chart.market_cap.thousand", "chart.market_cap.million", "chart.market_cap.billion"]

    static func marketCap(value: Decimal?) throws -> (value: Decimal, postfix: String?) {
        guard let value = value else {
            throw FormatError.isNull
        }
        let ten: Decimal = 10

        var index = 0
        var power: Decimal = 1
        while value >= power {
            index += 1
            power = pow(ten, index * 3)
        }
        switch index {
        case 0: throw FormatError.lessOne
        case 1: return (value: value, postfix: nil)
        case (postfixes.count + 2)...Int.max: throw FormatError.moreTrillions
        default: return (value: value / pow(ten, (index - 1) * 3), postfix: MarketCapFormatter.postfixes[index - 2])
        }
    }

}
