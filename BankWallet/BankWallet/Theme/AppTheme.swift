import UIKit
import ActionSheet

class AppTheme {
    static var blurStyle: UIBlurEffect.Style { return App.shared.localStorage.lightMode ? .prominent : .dark }
    static var actionSheetBlurStyle: UIBlurEffect.Style { return App.shared.localStorage.lightMode ? .dark : .light }

    static var keyboardAppearance: UIKeyboardAppearance { return App.shared.localStorage.lightMode ? .default : .dark }
    static var textFieldTintColor: UIColor { return .cryptoYellow }

    public static let defaultAnimationDuration = 0.3

    static var actionSheetBackgroundColor: UIColor { return .crypto_Dark_Bars }
    static var controllerBackground: UIColor { return .crypto_Dark_Bars }
    static var controllerBackgroundFromGradient: UIColor { return .crypto_Dark_Bars }
    static var controllerBackgroundToGradient: UIColor { return .crypto_Dark_LightBackground }
    static let tabBarSeparatorColor: UIColor = .cryptoSteel20
    static var navigationBarStyle: UIBarStyle { return App.shared.localStorage.lightMode ? .default : .blackTranslucent}
    static var navigationBarTintColor = UIColor.cryptoYellow
    static var navigationBarBackgroundColor: UIColor { return .crypto_Dark96_Bars96 }
    static var statusBarStyle: UIStatusBarStyle { return App.shared.localStorage.lightMode ? .default : .lightContent}

    static let separatorColor = UIColor.cryptoSteel20
    static var darkSeparatorColor: UIColor { return .crypto_Black50_Steel20 }

    static var actionSheetConfig: ActionSheetThemeConfig {
        get {
            return ActionSheetThemeConfig(
                    actionStyle: .sheet(showDismiss: false),
                    topMargin: 0,
                    cornerRadius: 16,
                    separatorColor: UIColor.cryptoSteel20,
                    backgroundStyle: .blur(intensity: 0.55, style: AppTheme.actionSheetBlurStyle))
        }
    }
    static let alertSmallMargin: CGFloat = 8
    static let alertMediumMargin: CGFloat = 12
    static let alertBigMargin: CGFloat = 20

    static var alertBackgroundColor: UIColor { return .crypto_SteelDark_Bars }
    static let alertHeaderHeight: CGFloat = 40
    static let alertHeaderFont: UIFont = .cryptoSectionCaption
    static let alertHeaderColor: UIColor = .cryptoGray

    static let alertTitleHeight: CGFloat = 48
    static let alertTitleFont: UIFont = .cryptoHeadline
    static var alertTitleColor: UIColor { return .crypto_White_Black }

    static let alertTextMargin: CGFloat = 16
    static let alertTextFont: UIFont = .cryptoCaptionMedium
    static var alertTextColor: UIColor = .cryptoGray

    static let alertCellHeight: CGFloat = 53
    static let alertCellFont: UIFont = .cryptoHeadline
    static let alertMessageFont: UIFont = .cryptoCaptionMedium
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

    static let closeButtonColor: UIColor = .cryptoYellow
}
