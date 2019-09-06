import UIKit

class RestoreAccountsTheme {
    static let rowHeight: CGFloat = 73 + RestoreAccountsTheme.cellBottomMargin

    static let cellBigPadding: CGFloat = 12
    static let cellSmallPadding: CGFloat = 8
    static let cellBottomMargin: CGFloat = 12

    static var roundedBackgroundColor: UIColor { return .crypto_Steel20_White }
    static var roundedSelectedBackgroundColor: UIColor { return .crypto_Steel20_Steel40 }
    static let roundedBackgroundCornerRadius: CGFloat = 15
    static var roundedBackgroundShadowColor: UIColor { return .crypto_Black20_Steel20 }
    static var roundedBackgroundShadowOpacity: Float { return App.shared.localStorage.lightMode ? 0.8 : 1 }

    static let descriptionFont: UIFont = .cryptoSubhead1
    static var descriptionColor: UIColor = .cryptoGray
    static var descriptionTopMargin: CGFloat = 12
    static var descriptionSideMargin: CGFloat = 16
    static var descriptionBottomMargin: CGFloat = 24

    static let keyImageSize: CGFloat = 24
    static let keyImageColor: UIColor = .cryptoGray50

    static let cellTitleFont: UIFont = .cryptoHeadline2
    static var cellTitleColor: UIColor { return .crypto_Bars_Black }

    static let coinsFont: UIFont = .cryptoSubhead2
    static let coinsColor: UIColor = .cryptoGray
}
