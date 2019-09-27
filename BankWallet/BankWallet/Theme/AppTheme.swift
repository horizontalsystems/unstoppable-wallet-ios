import UIKit
import ActionSheet

class AppTheme {
    static var textFieldTintColor: UIColor { return .cryptoYellow }

    public static let defaultAnimationDuration = 0.3

    static var actionSheetBackgroundColor: UIColor { return .crypto_Dark_Bars }
    static var controllerBackground: UIColor { return .crypto_Dark_Bars }
    static var controllerBackgroundFromGradient: UIColor { return .crypto_Dark_Bars }
    static var controllerBackgroundToGradient: UIColor { return .crypto_Dark_LightBackground }
    static let tabBarSeparatorColor: UIColor = .cryptoSteel20
    static var navigationBarTintColor = UIColor.cryptoYellow
    static var navigationBarBackgroundColor: UIColor { return .crypto_Dark96_Bars96 }

    static let separatorColor = UIColor.cryptoSteel20
    static var darkSeparatorColor: UIColor { return .crypto_Black50_Steel20 }

    static var actionSheetConfig: ActionSheetThemeConfig {
        get {
            return ActionSheetThemeConfig(
                    actionStyle: .sheet(showDismiss: false),
                    topMargin: 0,
                    cornerRadius: 16,
                    separatorColor: UIColor.cryptoSteel20,
                    backgroundStyle: .blur(intensity: 0.55, style: App.theme.actionSheetBlurStyle))
        }
    }
    static let viewMargin: CGFloat = 16

    static let alertSmallMargin: CGFloat = 8
    static let alertMediumMargin: CGFloat = 12
    static let alertBigMargin: CGFloat = 20
    static let alertCloseWidth: CGFloat = 48

    static var alertBackgroundColor: UIColor { return .crypto_SteelDark_Bars }
    static let alertHeaderHeight: CGFloat = 40
    static let alertHeaderFont: UIFont = .cryptoSubhead1
    static let alertHeaderColor: UIColor = .cryptoGray

    static let alertTitleHeight: CGFloat = 62
    static let alertTitleFont: UIFont = .cryptoHeadline2
    static var alertTitleColor: UIColor { return .crypto_White_Black }
    static let alertSubtitleTopMargin: CGFloat = 3
    static var alertSubtitleFont: UIFont = .cryptoCaption
    static var alertSubtitleColor: UIColor  = .cryptoGray

    static let alertTextMargin: CGFloat = 16
    static let alertTextFont: UIFont = .cryptoSubhead1
    static var alertTextColor: UIColor = .cryptoGray

    static let footerTextMargin: CGFloat = 16
    static let footerTextColor: UIColor = .cryptoGray
    static let footerTextFont: UIFont = .cryptoSubhead2

    static let alertCellHeight: CGFloat = 53
    static let alertCellFont: UIFont = .cryptoHeadline2
    static let alertMessageFont: UIFont = .cryptoSubhead1
    static var alertCellHighlightColor: UIColor = .cryptoYellow
    static var alertCellDefaultColor: UIColor { return .crypto_Bars_Dark }
    static var alertMessageDefaultColor: UIColor { return .crypto_Bars_Black }

    static let alertSideMargin: CGFloat = 61
    static var alertConfig: ActionSheetThemeConfig {
        return ActionSheetThemeConfig(
                actionStyle: .alert,
                sideMargin: AppTheme.alertSideMargin,
                cornerRadius: 16,
                separatorColor: UIColor.cryptoBlack20,
                backgroundStyle: .color(color: .cryptoBlack50)
        )
    }

    static let coinIconColor: UIColor = .cryptoGray
    static let coinIconSize: CGFloat = 24

    static let closeButtonColor: UIColor = .cryptoGray

    static let progressStepsCount = 3
}

extension CGFloat {
    static let cornerRadius2: CGFloat = 2
    static let cornerRadius4: CGFloat = 4
    static let cornerRadius8: CGFloat = 8
    static let cornerRadius16: CGFloat = 16

    static let margin1x: CGFloat = 4
    static let margin2x: CGFloat = 8
    static let margin3x: CGFloat = 12
    static let margin4x: CGFloat = 16
    static let margin6x: CGFloat = 24
    static let margin8x: CGFloat = 32
    static let margin10x: CGFloat = 40
    static let margin12x: CGFloat = 48

    static let marginButtonSide: CGFloat = 44

    static let heightOnePixel: CGFloat = 1 / UIScreen.main.scale
    static let heightSingleLineCell: CGFloat = 44
    static let heightDoubleLineCell: CGFloat = 60
    static let heightButton: CGFloat = 50
    static let heightButtonSecondary: CGFloat = 32
}

extension UIButton {

    static var appYellow: UIButton {
        let button = UIButton()

        button.titleLabel?.font = .cryptoHeadline2
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.appGray50, for: .disabled)
        button.setBackgroundColor(color: .appJacob, gradient: (colors: [UIColor(white: 1, alpha: 0.5), UIColor(white: 1, alpha: 0)], height: .heightButton), forState: .normal)
        button.setBackgroundColor(color: .appJacob, forState: .highlighted)
        button.setBackgroundColor(color: .appSteel20, forState: .disabled)
        button.cornerRadius = .cornerRadius8

        return button
    }

    static var appGray: UIButton {
        let button = UIButton()

        button.titleLabel?.font = .cryptoHeadline2
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.appGray50, for: .disabled)
        button.setBackgroundColor(color: .appLightGray, gradient: (colors: [UIColor(white: 1, alpha: 1), UIColor(white: 1, alpha: 0)], height: .heightButton), forState: .normal)
        button.setBackgroundColor(color: .appLightGray, forState: .highlighted)
        button.setBackgroundColor(color: .appSteel20, forState: .disabled)
        button.cornerRadius = .cornerRadius8

        return button
    }

    static var appSecondary: UIButton {
        let button = UIButton()

        button.titleLabel?.font = .cryptoSubhead1
        button.setTitleColor(.appOz, for: .normal)
        button.setTitleColor(.appGray50, for: .disabled)
        button.setBackgroundColor(color: .appElena, gradient: (colors: [UIColor(white: 1, alpha: App.theme.alphaSecondaryButtonGradient), UIColor(white: 1, alpha: 0)], height: .heightButtonSecondary), forState: .normal)
        button.setBackgroundColor(color: .appElena, forState: .highlighted)
        button.setBackgroundColor(color: .appElena, forState: .disabled)
        button.cornerRadius = .cornerRadius4
        button.borderColor = .appSteel20
        button.borderWidth = 1
        button.contentEdgeInsets.left = .margin2x
        button.contentEdgeInsets.right = .margin2x

        return button
    }

}

extension TimeInterval {
    static let defaultAnimationDuration: TimeInterval = 0.3
}
