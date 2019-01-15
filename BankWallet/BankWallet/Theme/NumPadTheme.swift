import UIKit

class NumPadTheme {
    static let size: CGSize = CGSize(width: 276, height: 308)
    static let itemSpacing: CGFloat = 6
    static let lineSpacing: CGFloat = 7

    static let itemSize: CGSize = CGSize(width: 84, height: 68)
    static let itemHeight: CGFloat = 47
    static let itemBorderWidth: CGFloat = 1
    static var itemBorderColor: UIColor { return .crypto_Steel20_Clear }
    static let itemCornerRadius: CGFloat = 8

    static var buttonBackgroundColor: UIColor { return .crypto_Steel20_White }
    static var buttonBackgroundColorHighlighted: UIColor { return .crypto_Steel20_Steel40 }

    static let numberFont: UIFont = .systemFont(ofSize: 25)
    static var numberColor: UIColor { return .crypto_White_Black }
    static let numberTopMargin: CGFloat = 8
    static let letteredNumberTopMargin: CGFloat = 1

    static let lettersFont: UIFont = .systemFont(ofSize: 10, weight: .medium)
    static let lettersColor: UIColor = .cryptoGray50
}
