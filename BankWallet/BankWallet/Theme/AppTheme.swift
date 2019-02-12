import UIKit
import GrouviActionSheet

class AppTheme {
    static var blurStyle: UIBlurEffect.Style { return App.shared.localStorage.lightMode ? .prominent : .dark }
    static var actionSheetBlurStyle: UIBlurEffect.Style { return App.shared.localStorage.lightMode ? .dark : .light }

    static var keyboardAppearance: UIKeyboardAppearance { return App.shared.localStorage.lightMode ? .default : .dark }
    static var textFieldTintColor: UIColor { return .crypto_White_Black }

    public static let defaultAnimationDuration = 0.3

    static var actionSheetBackgroundColor: UIColor { return .crypto_Dark_Bars }
    static var controllerBackground: UIColor { return .crypto_Dark_LightBackground }
    static var tabBarStyle: UIBarStyle { return App.shared.localStorage.lightMode ? .default : .black }
    static var navigationBarStyle: UIBarStyle { return App.shared.localStorage.lightMode ? .default : .blackTranslucent}
    static var navigationBarTintColor = UIColor.cryptoYellow
    static var statusBarStyle: UIStatusBarStyle { return App.shared.localStorage.lightMode ? .default : .lightContent}

    static var actionSheetConfig: ActionSheetThemeConfig {
        get {
            return ActionSheetThemeConfig(
                    actionStyle: .sheet(showDismiss: false),
                    topMargin: 8,
                    cornerRadius: 16,
                    separatorColor: UIColor.crypto_Steel40OnDark_Steel20,
                    backgroundStyle: .blur(intensity: 0.55, style: AppTheme.actionSheetBlurStyle))
        }
    }
    static let actionAlertConfig = ActionSheetThemeConfig(actionStyle: .alert, cornerRadius: 16)

    static let coinIconColor: UIColor = .cryptoGray
    static let coinIconSize: CGFloat = 24
}
