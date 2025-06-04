import SwiftUI
import UIKit

public extension Font {
    private static func manRopeFont(size: CGFloat, weight: Font.Weight) -> Font {
        switch weight {
        case .regular: return Font.custom("Manrope-Regular", size: size)
        case .medium: return Font.custom("Manrope-Medium", size: size)
        case .semibold: return Font.custom("Manrope-SemiBold", size: size)
        default: fatalError("Can't provide other weight for Manrope!")
        }
    }

    static let themeTitle1: Font = .manRopeFont(size: 38, weight: .semibold)
    static let themeTitle2: Font = .manRopeFont(size: 36, weight: .medium)
    static let themeTitle2R: Font = .manRopeFont(size: 32, weight: .regular)
    static let themeTitle3: Font = .manRopeFont(size: 24, weight: .semibold)
    static let themeHeadline1: Font = .manRopeFont(size: 20, weight: .semibold)
    static let themeHeadline2: Font = .manRopeFont(size: 16, weight: .semibold)
    static let themeBody: Font = .manRopeFont(size: 16, weight: .medium)
    static let themeSubhead1: Font = .manRopeFont(size: 14, weight: .medium)
    static let themeSubhead1I: Font = .manRopeFont(size: 14, weight: .medium).italic()
    static let themeSubhead2: Font = .manRopeFont(size: 14, weight: .regular)
    static let themeCaption: Font = .manRopeFont(size: 12, weight: .regular)
    static let themeCaptionSB: Font = .manRopeFont(size: 12, weight: .semibold)
    static let themeMicro: Font = .manRopeFont(size: 10, weight: .regular)
    static let themeMicroSB: Font = .manRopeFont(size: 10, weight: .semibold)

}

public extension UIFont {
    private static func manRopeFont(ofSize size: CGFloat, weight: Font.Weight) -> UIFont {
        switch weight {
        case .regular: return UIFont(name: "Manrope-Regular", size: size)!
        case .medium: return UIFont(name: "Manrope-Medium", size: size)!
        case .semibold: return UIFont(name: "Manrope-SemiBold", size: size)!
        default: fatalError("Can't provide other weight for Manrope!")
        }
    }

    static let title1: UIFont = .manRopeFont(ofSize: 38, weight: .semibold)
    static let title2: UIFont = .manRopeFont(ofSize: 36, weight: .medium)
    static let title2R: UIFont = .manRopeFont(ofSize: 32, weight: .regular)
    static let title3: UIFont = .manRopeFont(ofSize: 24, weight: .semibold)
    static let headline1: UIFont = .manRopeFont(ofSize: 20, weight: .semibold)
    static let headline2: UIFont = .manRopeFont(ofSize: 16, weight: .semibold)
    static let body: UIFont = .manRopeFont(ofSize: 16, weight: .medium)
    static let subhead1: UIFont = .manRopeFont(ofSize: 14, weight: .medium)
    static let subhead1I: UIFont = .manRopeFont(ofSize: 14, weight: .medium).with(traits: .traitItalic)
    static let subhead2: UIFont = .manRopeFont(ofSize: 14, weight: .regular)
    static let caption: UIFont = .manRopeFont(ofSize: 12, weight: .regular)
    static let captionSB: UIFont = .manRopeFont(ofSize: 12, weight: .semibold)
    static let micro: UIFont = .manRopeFont(ofSize: 10, weight: .regular)
    static let microSB: UIFont = .manRopeFont(ofSize: 10, weight: .semibold)
}
