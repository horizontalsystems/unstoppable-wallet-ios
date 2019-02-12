import UIKit
import GrouviActionSheet

class SendTheme {
    static let margin: CGFloat = 16
    static let smallMargin: CGFloat = 8

    static var itemBackground: UIColor { return .crypto_Steel20_White }

    static var buttonBackground: RespondButton.Style { return [.active: .crypto_Steel20_LightBackground, .selected: .crypto_Steel40_LightGray, .disabled: UIColor.crypto_Steel20_LightBackground] }
    static let buttonBorderColor = UIColor.cryptoSteel20
    static let buttonCornerRadius: CGFloat = 4
    static var buttonIconColor: UIColor { return .crypto_White_Black }
    static let buttonIconColorDisabled: UIColor = .cryptoSteel20
    static let buttonTitleHorizontalMargin: CGFloat = 12
    static let buttonSize: CGFloat = 32
    static let buttonFont: UIFont = .systemFont(ofSize: 14, weight: .semibold)
    static let errorFont: UIFont = .systemFont(ofSize: 12, weight: .medium)
    static let errorColor: UIColor = .cryptoRed

    static let titleHeight: CGFloat = 52
    static let titleFont = UIFont.cryptoHeadline
    static var titleColor: UIColor { return .crypto_White_Black }

    static let amountHeight: CGFloat = 80
    static let amountFont: UIFont = .systemFont(ofSize: 17)
    static var amountColor: UIColor { return .crypto_Bars_Dark }
    static let amountPlaceholderColor: UIColor = .cryptoSteel40
    static let amountLineColor: UIColor = .cryptoSteel20
    static let amountLineTopMargin: CGFloat = 4
    static let amountLineHeight: CGFloat = 1
    static let amountInputTintColor: UIColor = .cryptoYellow
    static let amountHintFont: UIFont = .systemFont(ofSize: 12)
    static let amountHintColor: UIColor = .cryptoGray

    static let addressHeight: CGFloat = 64
    static let addressFont: UIFont = .systemFont(ofSize: 17)
    static var addressColor: UIColor { return .crypto_Bars_Dark }
    static let addressHintColor: UIColor = .cryptoSteel40
    static let addressErrorTopMargin: CGFloat = 4

    static let feeHeight: CGFloat = 40
    static let feeFont: UIFont = .systemFont(ofSize: 14)
    static let feeColor: UIColor = .cryptoGray

    static let sendHeight: CGFloat = 77
    static let sendButtonHeight: CGFloat = 50
    static let sendButtonCornerRadius: CGFloat = 8

    static let keyboardHeight: CGFloat = 209
    static let keyboardTopMargin: CGFloat = 0
    static let keyboardSideMargin: CGFloat = 7
    static let keyboardBottomMargin: CGFloat = 8

    static let confirmationAmountHeight: CGFloat = 78
    static let confirmationCurrencyAmountFont: UIFont = .cryptoTitle3
    static let confirmationCurrencyAmountColor: UIColor = .cryptoYellow
    static let confirmationCurrencyAmountTopMargin: CGFloat = 20
    static let confirmationAmountFont: UIFont = .cryptoCaption1
    static let confirmationAmountColor: UIColor = .cryptoGray
    static let confirmationAmountTopMargin: CGFloat = 4

    static let confirmationAddressHeight: CGFloat = 60

    static var hashBackground: UIColor { return .crypto_Steel20_LightBackground }
    static var hashBackgroundSelected: UIColor { return .crypto_Steel40_LightGray }
    static let hashWrapperBorderColor: UIColor = .cryptoSteel20
    static let hashBackgroundHeight: CGFloat = 28
    static let hashCornerRadius: CGFloat = 4
    static var hashColor: UIColor { return .crypto_Bars_Dark }

    static let confirmationValueHeight: CGFloat = 27
    static let valueFont: UIFont = .cryptoCaption1
    static let valueColor: UIColor = .cryptoGray

    static var confirmationSheetConfig: ActionSheetThemeConfig {
        return ActionSheetThemeConfig(
                actionStyle: .alert,
                sideMargin: 30,
                cornerRadius: 16,
                separatorColor: UIColor.crypto_Steel40OnDark_Steel20,
                backgroundStyle: .blur(intensity: 0.55, style: AppTheme.actionSheetBlurStyle)
        )
    }
}
