import UIKit

extension UIBlurEffect.Style {
    static var cryptoStyle: UIBlurEffect.Style { return App.shared.localStorage.lightMode ? .extraLight : dark }
}
