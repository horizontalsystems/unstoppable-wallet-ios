import UIKit

extension UIBlurEffect.Style {
    static var cryptoStyle: UIBlurEffect.Style { return UserDefaultsStorage.shared.lightMode ? .extraLight : dark }
}
