import UIKit

class NumPadTheme {
    static let columnCount: CGFloat = 3
    static let rowCount: CGFloat = 4

    static let itemSizeRatio: CGFloat = 1.2
    static let itemLineSpacingRatio: CGFloat = 5

    static let itemBorderWidth: CGFloat = 1
    static let itemBorderColor: UIColor = .appSteel20
    static let itemCornerRadius: CGFloat = 36

    static let buttonBackgroundColor: UIColor = .clear
    static var buttonBackgroundColorHighlighted: UIColor { return App.theme.colorLawrence }

    static let numberFont: UIFont = .appTitle2R
    static var numberColor: UIColor { return App.theme.colorLeah }
    static let letteredNumberTopMargin: CGFloat = 3

    static let lettersFont: UIFont = .systemFont(ofSize: 10, weight: .medium)
    static let lettersColor: UIColor = .cryptoGray50
}
