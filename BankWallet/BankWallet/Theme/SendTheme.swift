import UIKit
import GrouviActionSheet

class SendTheme {
    static let margin: CGFloat = 16
    static let smallMargin: CGFloat = 8
    static let buttonBorderColor = UIColor.cryptoSteel20
    static let buttonCornerRadius: CGFloat = 4
    static let buttonIconColor: UIColor = .black
    static let buttonIconColorDisabled: UIColor = .cryptoSteel20
    static let buttonTitleHorizontalMargin: CGFloat = 12
    static let buttonSize: CGFloat = 32
    static let buttonFont: UIFont = .systemFont(ofSize: 14, weight: .semibold)
    static let errorFont: UIFont = .systemFont(ofSize: 12, weight: .medium)
    static let errorColor: UIColor = .cryptoRed

    static let titleHeight: CGFloat = 52
    static let titleFont = UIFont.cryptoHeadline

    static let amountHeight: CGFloat = 80
    static let amountFont: UIFont = .systemFont(ofSize: 17)
    static let amountColor: UIColor = .cryptoDark
    static let amountLineColor: UIColor = .cryptoLightGray
    static let amountLineTopMargin: CGFloat = 4
    static let amountLineHeight: CGFloat = 1
    static let amountInputTintColor: UIColor = .cryptoYellow
    static let amountHintFont: UIFont = .systemFont(ofSize: 12)
    static let amountHintColor: UIColor = .cryptoGray

    static let addressHeight: CGFloat = 64
    static let addressFont: UIFont = .systemFont(ofSize: 17)
    static let addressColor: UIColor = .cryptoDark
    static let addressHintColor: UIColor = .cryptoSilver
    static let addressErrorTopMargin: CGFloat = 4

    static let feeHeight: CGFloat = 40
    static let feeFont: UIFont = .systemFont(ofSize: 14)
    static let feeColor: UIColor = .cryptoGray

    static let sendHeight: CGFloat = 78
    static let sendButtonHeight: CGFloat = 50
    static let sendButtonCornerRadius: CGFloat = 8

    static let confirmationAmountHeight: CGFloat = 85
    static let confirmationAmountFont: UIFont = .cryptoTitle3
    static let confirmationAmountColor: UIColor = .cryptoYellow
    static let confirmationAmountTopMargin: CGFloat = 20
    static let confirmationFiatAmountFont: UIFont = .cryptoCaption1
    static let confirmationFiatAmountColor: UIColor = .cryptoGray
    static let confirmationFiatAmountTopMargin: CGFloat = 4

    static let confirmationAddressHeight: CGFloat = 44

    static let hashBackground: UIColor = .cryptoLightBackground
    static let hashBackgroundSelected: UIColor = .cryptoLightGray
    static let hashWrapperBorderColor: UIColor = .cryptoSteel20
    static let hashBackgroundHeight: CGFloat = 28
    static let hashCornerRadius: CGFloat = 4
    static let hashColor: UIColor = .cryptoDark

    static let confirmationValueHeight: CGFloat = 27
    static let valueFont: UIFont = .cryptoCaption1
    static let valueColor: UIColor = .cryptoGray

    static let confirmationSheetConfig = ActionSheetThemeConfig(actionStyle: .alert, sideMargin: 30, cornerRadius: 16)
}
