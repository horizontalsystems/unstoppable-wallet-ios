import SwiftUI
import UIKit

public extension Font {
    static let themeTitle1: Font = .system(size: 40, weight: .bold)
    static let themeTitle2: Font = .system(size: 34, weight: .bold)
    static let themeTitle2R: Font = .system(size: 34, weight: .regular)
    static let themeTitle3: Font = .system(size: 22, weight: .bold)
    static let themeHeadline1: Font = .system(size: 22, weight: .semibold)
    static let themeHeadline2: Font = .system(size: 17, weight: .semibold)
    static let themeBody: Font = .system(size: 17, weight: .regular)
    static let themeSubhead1: Font = .system(size: 14, weight: .medium)
    static let themeSubhead1I: Font = .system(size: 14, weight: .medium).italic()
    static let themeSubhead2: Font = .system(size: 14, weight: .regular)
    static let themeCaption: Font = .system(size: 12, weight: .regular)
    static let themeCaptionSB: Font = .system(size: 12, weight: .semibold)
    static let themeMicro: Font = .system(size: 10, weight: .regular)
    static let themeMicroSB: Font = .system(size: 10, weight: .semibold)
}

public extension UIFont {
    static let title1: UIFont = .systemFont(ofSize: 40, weight: .bold)
    static let title2: UIFont = .systemFont(ofSize: 34, weight: .bold)
    static let title2R: UIFont = .systemFont(ofSize: 34, weight: .regular)
    static let title3: UIFont = .systemFont(ofSize: 22, weight: .bold)
    static let headline1: UIFont = .systemFont(ofSize: 22, weight: .semibold)
    static let headline2: UIFont = .systemFont(ofSize: 17, weight: .semibold)
    static let body: UIFont = .systemFont(ofSize: 17, weight: .regular)
    static let subhead1: UIFont = .systemFont(ofSize: 14, weight: .medium)
    static let subhead1I: UIFont = .systemFont(ofSize: 14, weight: .medium).with(traits: .traitItalic)
    static let subhead2: UIFont = .systemFont(ofSize: 14, weight: .regular)
    static let caption: UIFont = .systemFont(ofSize: 12, weight: .regular)
    static let captionSB: UIFont = .systemFont(ofSize: 12, weight: .semibold)
    static let micro: UIFont = .systemFont(ofSize: 10, weight: .regular)
    static let microSB: UIFont = .systemFont(ofSize: 10, weight: .semibold)
}
