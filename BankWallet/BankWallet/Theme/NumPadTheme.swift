import UIKit

class NumPadTheme {
    static let size: CGSize = CGSize(width: 276, height: 308)
    static let spacing: CGFloat = 12

    static let itemSize: CGSize = CGSize(width: 84, height: 68)
    static let itemBorderWidth: CGFloat = 1
    static var itemBorderColor: UIColor { return .crypto_Steel40_Steel20 }
    static let itemCornerRadius: CGFloat = 16

    static var buttonBackgroundColor: UIColor { return .crypto_Steel20_White }
    static var buttonBackgroundColorHighlighted: UIColor { return .crypto_Steel20_Steel40 }

    static let numberFont: UIFont = .systemFont(ofSize: 30)
    static var numberColor: UIColor { return .crypto_White_Black }
    static let numberTopMargin: CGFloat = 8

    static let lettersFont: UIFont = .systemFont(ofSize: 12, weight: .medium)
    static let lettersColor: UIColor = .cryptoGray
    static let lettersBottomMargin: CGFloat = 8
}
