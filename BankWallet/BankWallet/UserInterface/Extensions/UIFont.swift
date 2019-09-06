import UIKit

extension UIFont {

    static let cryptoTitle1 = UIFont.systemFont(ofSize: 40, weight: .bold)
    static let cryptoTitle2 = UIFont.systemFont(ofSize: 34, weight: .bold)
    static let cryptoTitle3 = UIFont.systemFont(ofSize: 22, weight: .bold)
    static let cryptoHeadline1 = UIFont.systemFont(ofSize: 22, weight: .semibold)
    static let cryptoHeadline2 = UIFont.systemFont(ofSize: 17, weight: .semibold)
    static let cryptoBody = UIFont.systemFont(ofSize: 17, weight: .regular)

    static let cryptoSubhead1 = UIFont.systemFont(ofSize: 14, weight: .medium)
    static let cryptoSubhead2 = UIFont.systemFont(ofSize: 14, weight: .regular)
    static let cryptoSubheadItalic = UIFont.systemFont(ofSize: 15, weight: .regular).with(traits: .traitItalic)

    static let cryptoCaption = UIFont.systemFont(ofSize: 12, weight: .regular)
    static let cryptoMicro = UIFont.systemFont(ofSize: 10, weight: .regular)

    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: descriptor, size: 0)
    }

}
