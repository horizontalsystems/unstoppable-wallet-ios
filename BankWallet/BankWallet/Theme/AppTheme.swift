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

    // New styles

    static let margin1x: CGFloat = 4
    static let margin2x: CGFloat = 8
    static let margin3x: CGFloat = 12
    static let margin4x: CGFloat = 16
    static let margin6x: CGFloat = 24
    static let margin8x: CGFloat = 32
    static let margin10x: CGFloat = 40
    static let margin12x: CGFloat = 48

    static let heightDoubleLineCell: CGFloat = 60
}
