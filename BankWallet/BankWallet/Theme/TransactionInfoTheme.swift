import UIKit

class TransactionInfoTheme {

    static let hashButtonMargin: CGFloat = 48
    static let largeMargin: CGFloat = 32
    static let regularMargin: CGFloat = 16
    static let middleMargin: CGFloat = 8
    static let smallMargin: CGFloat = 4

    static let itemHeight: CGFloat = 45

    static let titleHeight: CGFloat = 54
    static let titleFont = UIFont.cryptoHeadline
    static var titleColor: UIColor { return .crypto_White_Black }
    static let dateFont = UIFont.cryptoCaption1
    static let dateColor = UIColor.cryptoGray

    static var itemBackground: UIColor { return .crypto_Steel20_White }
    static let itemTitleFont: UIFont = .systemFont(ofSize: 15)
    static let itemTitleColor = UIColor.cryptoGray
    static let itemValueFont: UIFont = .systemFont(ofSize: 15, weight: .medium)
    static var itemValueColor: UIColor { return .crypto_Bars_Dark }
    static let hashButtonHeight: CGFloat = 28
    static let hashButtonCornerRadius: CGFloat = 4
    static var hashButtonBackground: UIColor { return .crypto_Steel20_LightBackground }
    static var hashButtonBackgroundSelected: UIColor { return .crypto_Steel40_LightGray }
    static let hashButtonBorderColor = UIColor.cryptoSteel20
    static let hashButtonHashTextColor: UIColor = .cryptoGray
    static let hashButtonIconColor: UIColor = .cryptoGray50

    static let amountHeight: CGFloat = 86
    static let amountFont = UIFont.cryptoTitle3
    static let fiatAmountFont = UIFont.cryptoCaption1
    static let fiatAmountColor = UIColor.cryptoGray
    static let incomingAmountColor = UIColor.cryptoGreen
    static let outgoingAmountColor = UIColor.cryptoYellow

    static let barsProgressBarWidth: CGFloat = 4
    static let barsProgressHeight: CGFloat = 16
    static let barsProgressColor: UIColor = .cryptoGreen
    static let barsProgressInactiveColor: UIColor = .cryptoSteel20

    static let openFullInfoHeight: CGFloat = 52
    static let openFullInfoButtonBackground = UIColor.clear
    static let openFullInfoButtonTextColor = UIColor.cryptoGray
    static let openFullInfoButtonTextColorSelected = UIColor.cryptoSilver

}
