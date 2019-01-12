import UIKit

class RequestErrorTheme {
    static var buttonBackground: RespondButton.Style {
        return [.active: .crypto_Steel20_LightBackground, .selected: .crypto_Steel40_LightGray, .disabled: UIColor.crypto_Steel20_LightBackground]
    }
    static let buttonBorderColor = UIColor.cryptoSteel20
    static let buttonCornerRadius: CGFloat = 4
    static var buttonIconColor: UIColor {
        return .crypto_Bars_Black
    }
    static let buttonIconColorDisabled: UIColor = .cryptoSteel20
    static let buttonTitleHorizontalMargin: CGFloat = 12
    static let buttonSize: CGFloat = 32
    static let buttonFont: UIFont = .systemFont(ofSize: 14, weight: .semibold)

    static let titleMargin: CGFloat = 24
    static let subtitleMargin: CGFloat = 4
    static let buttonMargin: CGFloat = 16

}