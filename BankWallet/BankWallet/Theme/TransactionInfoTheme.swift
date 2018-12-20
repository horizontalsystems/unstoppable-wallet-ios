import UIKit

class TransactionInfoTheme {

    static let largeMargin: CGFloat = 32
    static let regularMargin: CGFloat = 16
    static let middleMargin: CGFloat = 8
    static let smallMargin: CGFloat = 4

    static let titleHeight: CGFloat = 54
    static let titleFont = UIFont.cryptoHeadline
    static var titleColor: UIColor { return .crypto_White_Black }
    static let dateFont = UIFont.cryptoCaption1
    static let dateColor = UIColor.cryptoGray

    static var itemBackground: UIColor { return .crypto_Steel20_White }
    static let itemTitleColor = UIColor.cryptoGray
    static let itemTitleFont = UIFont.cryptoCaption1
    static let hashButtonHeight: CGFloat = 28
    static let hashButtonCornerRadius: CGFloat = 4
    static var hashButtonBackground: UIColor { return .crypto_Steel20_LightBackground }
    static var hashButtonBackgroundSelected: UIColor { return .crypto_Steel40_LightGray }
    static let hashButtonBorderColor = UIColor.cryptoSteel20
    static var hashButtonTextColor: UIColor { return .crypto_Bars_Dark }
    static let hashButtonIconColor: UIColor = .cryptoGray50

    static let amountHeight: CGFloat = 99
    static let amountTopMargin: CGFloat = 20
    static let amountFont = UIFont.cryptoTitle3
    static let fiatAmountFont = UIFont.cryptoCaption1
    static let fiatAmountColor = UIColor.cryptoGray
    static let incomingAmountColor = UIColor.cryptoGreen
    static let outgoingAmountColor = UIColor.cryptoYellow

    static let itemHeight: CGFloat = 45

    static let statusImageWidth: CGFloat = 13
    static let statusImageHeight: CGFloat = 12
    static let successIconTintColor = UIColor.cryptoGreen
    static let processingIconTintColor = UIColor.cryptoGray

    static let closeHeight: CGFloat = 52
    static let closeButtonBackground = UIColor.clear
    static let closeButtonTextColor = UIColor.cryptoGray
    static let closeButtonTextColorSelected = UIColor.cryptoSilver

}
