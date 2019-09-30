import UIKit

class ChartRateTheme {
    static let currentRateHeight: CGFloat = 44
    static let smallMargin: CGFloat = 10
    static let mediumMargin: CGFloat = 12
    static let margin: CGFloat = 16

    static let currentRateFont = UIFont.appHeadline2
    static var currentRateColor: UIColor { return .crypto_Bars_Dark }

    static let diffRateFont = UIFont.appCaption
    static var diffRatePositiveColor: UIColor { return .cryptoGreen }
    static var diffRateNegativeColor: UIColor { return .cryptoRed }

    static let buttonMargin: CGFloat = 8
    static let buttonHeight: CGFloat = 32
    static let buttonDefaultWidth: CGFloat = 60

    static let chartRateTypeHeight: CGFloat = 48

    static let chartRateValueTopMargin: CGFloat = 6
    static let chartRateDateFont = UIFont.appCaption
    static let chartRateDateColor: UIColor = .cryptoGray
    static let chartRateDateTopMargin: CGFloat = 1
    static let chartRateValueFont = UIFont.appSubhead1
    static var chartRateValueColor: UIColor { return .crypto_Bars_Dark }

    static var buttonBackground: RespondButton.Style { return [.active: .crypto_Steel20_LightBackground, .selected: .cryptoGreen, .disabled: UIColor.crypto_Steel20_LightBackground] }
    static let buttonBorderColor = UIColor.cryptoSteel20
    static let buttonCornerRadius: CGFloat = 4
    static let buttonFont: UIFont = .appSubhead1
    static var buttonTextColor: UIColor { return .crypto_SteelDark_LightGray }
    static var buttonSelectedTextColor: UIColor { return .cryptoYellow }
    static var buttonDisabledTextColor: UIColor { return .cryptoGray50 }

    static let customProgressRadius: CGFloat = 11
    static let spinnerLineWidth: CGFloat = 3
    static var spinnerLineColor: UIColor { return .crypto_Bars_Dark }

    static let chartRateHeight: CGFloat = 218
    static let chartRateTopMargin: CGFloat = 8
    static let chartViewHeight: CGFloat = 210

    static let chartErrorFont: UIFont = .appSubhead1
    static let chartErrorColor: UIColor = .cryptoGray
    static let chartErrorMargin: CGFloat = 24

    static let chartMarketCapHeight: CGFloat = 44
    static let marketCapTitleTopMargin: CGFloat = 16
    static let marketCapTitleFont = UIFont.appCaption
    static let marketCapTitleColor: UIColor = .cryptoGray

    static let marketCapTextFont = UIFont.appSubhead2
    static var marketCapTextColor: UIColor { return .crypto_Bars_Dark }

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
