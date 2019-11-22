import UIKit
import ActionSheet

class SendTheme {
    static let margin: CGFloat = 16
    static let mediumMargin: CGFloat = 12
    static let smallMargin: CGFloat = 8

    static let holderCornerRadius: CGFloat = 8
    static let holderBorderWidth: CGFloat = 1
    static let holderBorderColor: UIColor = .cryptoSteel20
    static var holderBackground: UIColor { .crypto_SteelDark_White }

    static var buttonBackground: RespondButton.Style { [.active: .crypto_Steel20_LightBackground, .selected: .crypto_Steel40_LightGray, .disabled: UIColor.crypto_Steel20_LightBackground] }
    static let buttonBorderColor = UIColor.cryptoSteel20
    static let buttonCornerRadius: CGFloat = 4
    static var buttonIconColor: UIColor { .crypto_White_Black }
    static let buttonSize: CGFloat = 32
    static let scanButtonWidth: CGFloat = 36
    static let errorColor: UIColor = .cryptoRed

    static let addressHeight: CGFloat = 56
    static let addressHolderHeight: CGFloat = 44
    static let addressFont: UIFont = .appBody
    static var addressColor: UIColor { .crypto_Bars_Dark }
    static let addressHintColor: UIColor = .cryptoSteel40
    static let addressTextViewLineHeight: Int = 22

    static let feeFont: UIFont = .systemFont(ofSize: 14)
    static let feeColor: UIColor = .cryptoGray

    static let hodlerHeight: CGFloat = 44

    static let sendSmallButtonMargin: CGFloat = 6

    static let sendButtonHolderHeight: CGFloat = 74
    static let sendButtonHeight: CGFloat = 50
    static let sendButtonCornerRadius: CGFloat = 8

    static let confirmationPrimaryHeight: CGFloat = 72

    static let memoHeight: CGFloat = 56
    static let memoInputFieldMargin: CGFloat = 12
    static let memoHolderTopMargin: CGFloat = 12

    static let confirmationAdditionalPadding: CGFloat = 4
    static let confirmationFieldHeight: CGFloat = 24

    static let confirmationAmountVerticalMargin: CGFloat = 12

    static let confirmationPrimaryAmountFont: UIFont = .appHeadline1
    static let confirmationPrimaryAmountColor: UIColor = .appJacob
    static let confirmationSecondaryAmountTitleFont: UIFont = .appHeadline2
    static let confirmationSecondaryAmountTitleColor: UIColor = .appOz
    static let confirmationBottomAmountFont: UIFont = .appSubhead2
    static let confirmationBottomAmountColor: UIColor = .appGray

    static let confirmationMemoVerticalMargin: CGFloat = 14

    static let confirmationMemoHeight: CGFloat = 44
    static let confirmationMemoTitleFont: UIFont = .appSubhead1
    static let confirmationMemoTitleColor: UIColor = .appGray
    static let confirmationMemoFont: UIFont = .appSubhead1I
    static let confirmationMemoColor: UIColor = .appOz

    static let confirmationToLabelFont: UIFont = .appSubhead2
    static let confirmationToLabelColor: UIColor = .cryptoGray
    static let confirmationToLabelTopMargin: CGFloat = 13
    static let confirmationReceiverTopMargin: CGFloat = 8

    static let confirmationMemoPlaceholderColor: UIColor = .cryptoSteel40
    static let confirmationMemoInputTintColor: UIColor = .cryptoYellow
}
