import UIKit

class ManageAccountsTheme {
    static let rowHeight: CGFloat = 140

    static let cellBigPadding: CGFloat = 12
    static let cellSmallPadding: CGFloat = 8
    static let cellBottomMargin: CGFloat = 8

    static var roundedBackgroundColor: UIColor { return .crypto_SteelDark_White }
    static let roundedBackgroundCornerRadius: CGFloat = 15
    static var roundedBackgroundShadowColor: UIColor { return .crypto_Black20_Steel20 }
    static var roundedBackgroundShadowOpacity: Float { return App.shared.localStorage.lightMode ? 0.8 : 1 }

    static let cellTitleFont = UIFont.cryptoHeadline
    static var cellTitleColor: UIColor { return .crypto_White_Black }

    static let coinsFont = UIFont.cryptoCaption1
    static let coinsColor = UIColor.cryptoGray

    static let buttonsTopMargin: CGFloat = 16
    static let buttonsHeight: CGFloat = 50
    static let buttonCornerRadius: CGFloat = 8
}
