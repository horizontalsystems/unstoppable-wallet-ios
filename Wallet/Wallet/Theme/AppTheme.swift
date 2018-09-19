import UIKit

public class AppTheme {
    static var blurStyle: UIBlurEffectStyle { return UserDefaultsStorage.shared.lightMode ? .prominent : .dark }

    public static var keyboardAppearance: UIKeyboardAppearance { return UserDefaultsStorage.shared.lightMode ? .default : .dark }
    public static let textFieldTintColor: UIColor = .white

    public static let defaultAnimationDuration = 0.3

    static let actionSheetBackgroundColor = UIColor.cryptoBarsColor
    static let inputBackgroundColor = UIColor.white
    static var controllerBackground: UIColor { return .cryptoThemedDark }
    static var tabBarStyle: UIBarStyle { return UserDefaultsStorage.shared.lightMode ? .default : .black }
    static var navigationBarStyle: UIBarStyle { return UserDefaultsStorage.shared.lightMode ? .default : .blackTranslucent}
    static var navigationBarTintColor = UIColor.cryptoYellow
}
