import UIKit

extension UIBlurEffectStyle {
    static var cryptoStyle: UIBlurEffectStyle { return App.shared.localStorage.lightMode ? .extraLight : dark }
}
