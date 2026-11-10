import Down
import Foundation
import UIKit

enum ReleaseNotesMarkdownConfig {
    private static func colors(brandColor: BrandColor) -> StaticColorCollection {
        StaticColorCollection(
            heading1: brandColor.uiColor,
            heading2: brandColor.uiColor,
            body: .themeBran
        )
    }

    private static let paragraphStyles: StaticParagraphStyleCollection = {
        var paragraphStyles = StaticParagraphStyleCollection()

        let headingParagraphStyle = NSMutableParagraphStyle()

        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.lineSpacing = 6

        paragraphStyles.heading1 = headingParagraphStyle
        paragraphStyles.heading2 = headingParagraphStyle
        paragraphStyles.body = bodyParagraphStyle

        return paragraphStyles
    }()

    static func config(brandColor: BrandColor) -> DownStylerConfiguration {
        let fonts = StaticFontCollection(
            heading1: .title3,
            heading2: .headline2,
            body: .body
        )

        return DownStylerConfiguration(
            fonts: fonts,
            colors: colors(brandColor: brandColor),
            paragraphStyles: paragraphStyles
        )
    }
}
