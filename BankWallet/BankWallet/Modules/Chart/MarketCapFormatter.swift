import Foundation

class MarketCapFormatter {
    private static let postfixes = ["chart.market_cap.thousand", "chart.market_cap.million", "chart.market_cap.billion", "chart.market_cap.trillion"]

    static func marketCap(value: Decimal) -> (value: Decimal, postfix: String?) {
        let ten: Decimal = 10

        var index = 1
        var power: Decimal = 1000
        while value >= power {
            power = pow(ten, (index + 1) * 3)
            index += 1
            if index > postfixes.count {
                break
            }
        }
        let postfix: String? = index < 2 ? nil : MarketCapFormatter.postfixes[index - 2]
        return (value: value / pow(ten, (index - 1) * 3), postfix: postfix)
    }

}
