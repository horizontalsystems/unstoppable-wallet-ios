import UIKit

extension UIFont {

    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: descriptor, size: 0)
    }

}
