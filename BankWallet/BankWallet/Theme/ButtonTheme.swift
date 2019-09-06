import UIKit

class ButtonTheme {
    private static let greenActiveBackground = UIColor.cryptoGreen
    private static let greenSelectedBackground = UIColor.cryptoGreenPressed
    private static let disabledOnWhiteBackground = UIColor.cryptoSteel20
    private static let disabledOnDarkBackground = UIColor.cryptoSteel20
    private static let textColor = UIColor.black
    private static let textColorDisabledBackground = UIColor.cryptoGray50
    private static let yellowActiveBackground = UIColor.cryptoYellow
    private static let yellowSelectedBackground = UIColor.cryptoYellowPressed
    private static let redActiveBackground = UIColor.cryptoRed
    private static let redSelectedBackground = UIColor.cryptoRedPressed
    private static let grayActiveBackground = UIColor.cryptoLightGray
    private static let graySelectedBackground = UIColor.cryptoGray

    static let greenBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.greenActiveBackground, .selected: ButtonTheme.greenSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]
    static let yellowBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.yellowActiveBackground, .selected: ButtonTheme.yellowSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]
    static let redBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.redActiveBackground, .selected: ButtonTheme.redSelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]
    static let grayBackgroundDictionary: RespondButton.Style = [.active: ButtonTheme.grayActiveBackground, .selected: ButtonTheme.graySelectedBackground, .disabled: ButtonTheme.disabledOnDarkBackground]

    static let textColorDictionary: RespondButton.Style = [.active: ButtonTheme.textColor, .selected: ButtonTheme.textColor, .disabled: ButtonTheme.textColorDisabledBackground]
    static let whiteTextColorDictionary: RespondButton.Style = [.active: .white, .selected: .white, .disabled: ButtonTheme.textColorDisabledBackground]

    static let font = UIFont.cryptoHeadline2
    static let margin: CGFloat = 16
    static let imageMargin: CGFloat = 8

    static let verticalMargin: CGFloat = 16
    static let insideMargin: CGFloat = 6
}
