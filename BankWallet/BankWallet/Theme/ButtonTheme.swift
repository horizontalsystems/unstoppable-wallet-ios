import UIKit

class ButtonTheme {
    private static let greenActiveBackground = UIColor.cryptoGreen
    private static let greenSelectedBackground = UIColor.cryptoGreenPressed
    private static let disabledOnWhiteBackground = UIColor.cryptoSteel20
    private static let disabledOnDarkBackground = UIColor.lightGray
    private static let textColor = UIColor.black
    private static let textColorDisabledOnWhiteBackground = UIColor.gray
    private static let textColorDisabledOnDarkBackground = UIColor.cryptoSilver
    private static let yellowActiveBackground = UIColor.cryptoYellow
    private static let yellowSelectedBackground = UIColor.cryptoYellowPressed
    private static let grayActiveBackground = UIColor.cryptoLightBackground
    private static let graySelectedBackground = UIColor.cryptoLightGray

    static let greenBackgroundOnWhiteBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.greenActiveBackground, .selected: ButtonTheme.greenSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]
    static let yellowBackgroundOnWhiteBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.yellowActiveBackground, .selected: ButtonTheme.yellowSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]

    static let grayBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.grayActiveBackground, .selected: ButtonTheme.graySelectedBackground, .disabled: ButtonTheme.disabledOnWhiteBackground]

    static let greenBackgroundOnDarkBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.greenActiveBackground, .selected: ButtonTheme.greenSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]
    static let yellowBackgroundOnDarkBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.yellowActiveBackground, .selected: ButtonTheme.yellowSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]

    static let textColorOnWhiteBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.textColor, .selected: ButtonTheme.textColor, .disabled: ButtonTheme.textColorDisabledOnWhiteBackground]
    static let textColorOnDarkBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.textColor, .selected: ButtonTheme.textColor, .disabled: ButtonTheme.textColorDisabledOnDarkBackground]

    static let font = UIFont.cryptoHeadline
    static let margin: CGFloat = 16
}
