import UIKit

class ButtonTheme {
    private static let greenActiveBackground = UIColor.cryptoGreen
    private static let greenSelectedBackground = UIColor.cryptoGreenPressed
    private static let disabledOnWhiteBackground = UIColor.cryptoSteel20
    private static let disabledOnDarkBackground = UIColor.cryptoSteel20
    private static let textColor = UIColor.black
    private static let textColorDisabledOnWhiteBackground = UIColor.cryptoGray50
    private static let textColorDisabledOnDarkBackground = UIColor.cryptoGray50
    private static let yellowActiveBackground = UIColor.cryptoYellow
    private static let yellowSelectedBackground = UIColor.cryptoYellowPressed
    private static let redActiveBackground = UIColor.cryptoRed
    private static let redSelectedBackground = UIColor.cryptoRedPressed
    private static let grayActiveBackground = UIColor.cryptoLightBackground
    private static let graySelectedBackground = UIColor.cryptoLightGray

    static let greenBackgroundOnWhiteBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.greenActiveBackground, .selected: ButtonTheme.greenSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]
    static let yellowBackgroundOnWhiteBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.yellowActiveBackground, .selected: ButtonTheme.yellowSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]
    static let redBackgroundOnWhiteBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.redActiveBackground, .selected: ButtonTheme.redSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]

    static let greenBackgroundOnDarkBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.greenActiveBackground, .selected: ButtonTheme.greenSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]
    static let yellowBackgroundOnDarkBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.yellowActiveBackground, .selected: ButtonTheme.yellowSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]

    static let textColorOnWhiteBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.textColor, .selected: ButtonTheme.textColor, .disabled: ButtonTheme.textColorDisabledOnWhiteBackground]
    static let textColorOnDarkBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.textColor, .selected: ButtonTheme.textColor, .disabled: ButtonTheme.textColorDisabledOnDarkBackground]
    static let whiteTextColorOnDarkBackgroundDictionary: RespondButton.Style = [.active: .white, .selected: .white, .disabled: ButtonTheme.textColorDisabledOnWhiteBackground]

    static let font = UIFont.cryptoHeadline
    static let margin: CGFloat = 16
}
