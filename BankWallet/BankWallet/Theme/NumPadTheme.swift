import UIKit

class NumPadTheme {
    static let itemSizeRatio: CGFloat = 3.6

    static let itemBorderWidth: CGFloat = 1
    static var itemBorderColor: UIColor { return .appSteel20 }
    static let itemCornerRadius: CGFloat = 36

    static var buttonBackgroundColor: UIColor { return .crypto_Steel20_White }
    static var buttonBackgroundColorHighlighted: UIColor { return .crypto_Steel20_Steel40 }

    static let numberFont: UIFont = .cryptoTitle2Regular
    static var numberColor: UIColor { return App.theme.colorLeah }
    static let letteredNumberTopMargin: CGFloat = 3

    static let lettersFont: UIFont = .systemFont(ofSize: 10, weight: .medium)
    static let lettersColor: UIColor = .cryptoGray50
}
