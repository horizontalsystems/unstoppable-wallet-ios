import Down
import Foundation
import UIKit

enum AcademyMarkdownConfig {
    private static func colors(brandColor: BrandColor) -> StaticColorCollection {
        StaticColorCollection(
            heading1: .themeLeah,
            heading2: brandColor.uiColor,
            heading3: brandColor.uiColor,
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
        paragraphStyles.heading3 = headingParagraphStyle
        paragraphStyles.body = bodyParagraphStyle

        return paragraphStyles
    }()

    static func config(brandColor: BrandColor) -> DownStylerConfiguration {
        let fonts = StaticFontCollection(
            heading1: .title2,
            heading2: .title3,
            heading3: .headline2,
            body: .body
        )

        return DownStylerConfiguration(
            fonts: fonts,
            colors: colors(brandColor: brandColor),
            paragraphStyles: paragraphStyles
        )
    }
}
