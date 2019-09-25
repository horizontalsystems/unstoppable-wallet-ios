import UIKit

class PinTheme {
    static let infoHorizontalMargin: CGFloat = 44
    static let infoVerticalMargin: CGFloat = 16
    static let cancelColor = UIColor.cryptoYellow
    static let cancelSelectedColor = UIColor.cryptoYellowPressed

    static var keyboardSideMargin: CGFloat { return UIScreen.main.bounds.width <= 320 ? 32 : 48 } // decrease margin only for small screen

    static var lockoutIconBackground: UIColor { return App.shared.localStorage.lightMode ? .white : .cryptoGray50 }
    static let lockoutIconBackgroundSideSize: CGFloat = 94
    static let lockoutLabelTopMargin: CGFloat = 24
    static let lockoutLabelFont = UIFont.cryptoBody
    static let lockoutLabelColor = UIColor.cryptoGray
    static let lockoutLabelSideMargin: CGFloat = 32

    static let dismissAnimationDuration: Double = 0.3
}
