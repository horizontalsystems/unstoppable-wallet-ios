import UIKit

extension UIFont {

    static let cryptoTitleHeavy = UIFont.systemFont(ofSize: 34, weight: .heavy)
    static let cryptoTitle1 = UIFont.systemFont(ofSize: 34, weight: .bold)
    static let cryptoTitle3 = UIFont.systemFont(ofSize: 22, weight: .bold)
    static let cryptoTitle4 = UIFont.systemFont(ofSize: 22, weight: .semibold)
    static let cryptoHeadline = UIFont.systemFont(ofSize: 17, weight: .semibold)
    static let cryptoBody2 = UIFont.systemFont(ofSize: 17, weight: .regular)
    static let cryptoCaptionItalic = UIFont.systemFont(ofSize: 15, weight: .regular).with(traits: .traitItalic)
    static let cryptoCaption = UIFont.systemFont(ofSize: 15, weight: .regular)
    static let cryptoCaption1 = UIFont.systemFont(ofSize: 14, weight: .regular)
    static let cryptoCaptionMedium = UIFont.systemFont(ofSize: 14, weight: .medium)
    static let cryptoSectionCaption = UIFont.systemFont(ofSize: 14, weight: .semibold)
    static let cryptoCaption2 = UIFont.systemFont(ofSize: 13, weight: .regular)
    static let cryptoCaption2Medium = UIFont.systemFont(ofSize: 13, weight: .medium)
    static let cryptoCaption3 = UIFont.systemFont(ofSize: 12, weight: .regular)

    func with(traits: UIFontDescriptorSymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: descriptor, size: 0)
    }

}
