import UIKit

class ManageAccountsTheme {
    static let rowHeight: CGFloat = 121

    static let cellBigPadding: CGFloat = 12
    static let cellSmallPadding: CGFloat = 8
    static let cellTopMargin: CGFloat = 12
    static let cellBottomMargin: CGFloat = 8

    static var gradientRoundedBackgroundColor: UIColor? { return App.shared.localStorage.lightMode ? nil : .cryptoSteel20 }

    static var roundedBackgroundColor: UIColor { return .crypto_SteelDark_White }
    static let roundedBackgroundCornerRadius: CGFloat = 15
    static var roundedBackgroundShadowColor: UIColor { return .crypto_Black20_Steel20 }
    static var roundedBackgroundShadowOpacity: Float { return App.shared.localStorage.lightMode ? 0.8 : 1 }

    static let attentionColor = UIColor.cryptoRed
    static let keyImageColor = UIColor.cryptoYellow
    static let nonActiveKeyImageColor = UIColor.cryptoGray50
    static let alertKeyImageColor = UIColor.cryptoGray

    static let cellTitleFont = UIFont.cryptoHeadline
    static var cellTitleColor: UIColor { return .crypto_White_Black }
    static var nonActiveCellColor: UIColor { return .cryptoGray50 }

    static let coinsFont = UIFont.cryptoCaption1
    static let coinsColor = UIColor.cryptoGray

    static var buttonsBackgroundColorDictionary: RespondButton.Style  { return [.active: .crypto_Steel20_LightBackground, .selected: .crypto_Steel40_LightGray, .disabled: .crypto_Steel20_LightBackground] }
    static var buttonsTextColorDictionary: RespondButton.Style { return [.active: .crypto_Bars_Dark, .selected: .crypto_Bars_Dark, .disabled: UIColor.cryptoGray50] }

    static let buttonsFont = UIFont.cryptoSectionCaption
    static let buttonsTopMargin: CGFloat = 16
    static let buttonsMargin: CGFloat = 16
    static let buttonsHeight: CGFloat = 32
    static let buttonsBorderColor: UIColor = .cryptoSteel20
    static let buttonCornerRadius: CGFloat = 8

    static let descriptionColor: UIColor = .cryptoGray
    static let descriptionFont: UIFont = .cryptoCaptionMedium
}
