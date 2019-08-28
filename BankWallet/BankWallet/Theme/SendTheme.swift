import UIKit
import ActionSheet

class SendTheme {
    static let margin: CGFloat = 16
    static let mediumMargin: CGFloat = 12
    static let smallMargin: CGFloat = 8
    static let tinyMargin: CGFloat = 5

    static let holderCornerRadius: CGFloat = 8
    static let holderBorderWidth: CGFloat = 1 / UIScreen.main.scale
    static let holderBorderColor: UIColor = .cryptoSteel20
    static var holderBackground: UIColor { return .crypto_SteelDark_White }
    static let holderLeadingPadding: CGFloat = 12
    static let holderTopPadding: CGFloat = 9

    static var buttonBackground: RespondButton.Style { return [.active: .crypto_Steel20_LightBackground, .selected: .crypto_Steel40_LightGray, .disabled: UIColor.crypto_Steel20_LightBackground] }
    static let buttonBorderColor = UIColor.cryptoSteel20
    static let buttonCornerRadius: CGFloat = 4
    static var buttonIconColor: UIColor { return .crypto_White_Black }
    static let buttonIconColorDisabled: UIColor = .cryptoSteel20
    static let buttonSize: CGFloat = 32
    static let scanButtonWidth: CGFloat = 36
    static let buttonFont: UIFont = .systemFont(ofSize: 14, weight: .semibold)
    static let errorFont: UIFont = .systemFont(ofSize: 12, weight: .medium)
    static let errorColor: UIColor = .cryptoRed

    static let titleHeight: CGFloat = 48
    static let titleFont = UIFont.cryptoHeadline
    static var titleColor: UIColor { return .crypto_White_Black }

    static let amountHeight: CGFloat = 72
    static let amountHolderHeight: CGFloat = 60
    static let amountFont: UIFont = .cryptoBody2
    static var amountColor: UIColor { return .crypto_Bars_Dark }
    static let amountPlaceholderColor: UIColor = .cryptoSteel40
    static let amountLineColor: UIColor = .cryptoSteel20
    static let amountLineTopMargin: CGFloat = 5
    static let amountLineHeight: CGFloat = 1
    static let amountInputTintColor: UIColor = .cryptoYellow
    static let amountHintFont: UIFont = .cryptoCaption3
    static let amountHintColor: UIColor = .cryptoGray
    static let amountTopMargin: CGFloat = 5
    static let amountErrorLabelTopMargin: CGFloat = 4

    static let addressHeight: CGFloat = 56
    static let addressHolderHeight: CGFloat = 44
    static let addressFont: UIFont = .cryptoBody2
    static var addressColor: UIColor { return .crypto_Bars_Dark }
    static let addressHintColor: UIColor = .cryptoSteel40
    static let addressTextViewLineHeight: Int = 22
    static let addressErrorTopMargin: CGFloat = 1
    static let addressErrorBottomMargin: CGFloat = 4

    static let feeHeight: CGFloat = 54
    static let feeTitleTopMargin: CGFloat = 12
    static let feeFont: UIFont = .systemFont(ofSize: 14)
    static let feeColor: UIColor = .cryptoGray

    static let feePriorityHeight: CGFloat = 60.5
    static let feePriorityWrapperHeight: CGFloat = 44
    static let feePriorityTitleFont: UIFont = .systemFont(ofSize: 14)
    static let feePriorityTitleColor: UIColor = .cryptoGray
    static let feePriorityTitleTopMargin: CGFloat = 28
    static let feePriorityValueFont: UIFont = .systemFont(ofSize: 14)
    static let feePriorityValueColor: UIColor = .lightGray
    static let feePriorityValueTopMargin: CGFloat = 29
    static let feePriorityValueLeftMargin: CGFloat = 10
    static let feePriorityValueRightMargin: CGFloat = 8
    static let feePriorityDropDownTopMargin: CGFloat = 32
    static let feePriorityLineHeight: CGFloat = 0.5
    static let feePriorityLineColor: UIColor = .cryptoSteel20
    static let feePriorityLineTopMargin: CGFloat = 13

    static let switchRightMargin: CGFloat = 6

    static let sendButtonHolderHeight: CGFloat = 74
    static let sendButtonHeight: CGFloat = 50
    static let sendButtonCornerRadius: CGFloat = 8

    static let confirmationPrimaryHeight: CGFloat = 134
    static let confirmationPrimaryMargin: CGFloat = 20
    static let confirmationPrimaryLineTopMargin: CGFloat = 89

    static let confirmationMemoHeight: CGFloat = 56
    static let confirmationMemoInputFieldMargin: CGFloat = 12
    static let confirmationHolderTopMargin: CGFloat = 12

    static let confirmationFieldSectionTopMargin: CGFloat = 4

    static let confirmationFieldHeight: CGFloat = 24

    static let confirmationPrimaryAmountFont: UIFont = .cryptoTitle4
    static let confirmationPrimaryAmountColor: UIColor = .cryptoYellow
    static let confirmationSecondaryFont: UIFont = .cryptoSectionCaption
    static let confirmationSecondaryColor: UIColor = .crypto_Bars_Dark
    static let confirmationSecondaryTopMargin: CGFloat = 8

    static let confirmationToLabelFont: UIFont = .cryptoCaption1
    static let confirmationToLabelColor: UIColor = .cryptoGray
    static let confirmationToLabelTopMargin: CGFloat = 13
    static let confirmationReceiverTopMargin: CGFloat = 8

    static let confirmationMemoPlaceholderColor: UIColor = .cryptoSteel40
    static let confirmationMemoInputTintColor: UIColor = .cryptoYellow
}
