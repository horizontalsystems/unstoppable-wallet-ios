import UIKit
import ActionSheet

class AppTheme {
    static var textFieldTintColor: UIColor { .themeJacob }

    public static let defaultAnimationDuration = 0.3

    static var actionSheetBackgroundColor: UIColor { .themeLawrence }
    static var controllerBackgroundFromGradient: UIColor { .themeTyler }
    static var controllerBackgroundToGradient: UIColor { .themeHelsing }
    static var navigationBarBackgroundColor: UIColor { UIColor.themeTyler.withAlphaComponent(0.96) }

    static var actionSheetConfig: ActionSheetThemeConfig {
        get {
            ActionSheetThemeConfig(
                    actionStyle: .sheet(showDismiss: false),
                    topMargin: 0,
                    cornerRadius: 16,
                    separatorColor: .themeSteel20,
                    backgroundStyle: .color(color: .themeBlack50)
            )
        }
    }
    static let alertBigMargin: CGFloat = 20

    static let alertHeaderHeight: CGFloat = 40

    static let alertTitleHeight: CGFloat = 62
    static let alertSubtitleTopMargin: CGFloat = 3

    static let alertSideMargin: CGFloat = 61

    static let coinIconSize: CGFloat = 24

    static let progressStepsCount = 3
}
