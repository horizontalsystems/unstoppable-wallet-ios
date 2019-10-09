import UIKit

class ChartRateTheme {

    static let diffFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()

    static func formatted(percentDelta: Decimal) -> String {
        let formatter = ChartRateTheme.diffFormatter
        var sign = percentDelta.isSignMinus ? "- " : "+ "
        sign = percentDelta == 0 ? "" : sign
        return [sign, formatter.string(from: abs(percentDelta) as NSNumber), "%"].compactMap { $0 }.joined()
    }

}
