import Foundation
import UIKit
import ThemeKit
import Down

struct AcademyMarkdownConfig {

    private static let colors = StaticColorCollection(
            heading1: .themeLeah,
            heading2: .themeJacob,
            heading3: .themeJacob,
            body: .themeBran
    )

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

    static var config: DownStylerConfiguration {
        let fonts = StaticFontCollection(
                heading1: .title2,
                heading2: .title3,
                heading3: .headline2,
                body: .body
        )

        return DownStylerConfiguration(
                fonts: fonts,
                colors: colors,
                paragraphStyles: paragraphStyles
        )
    }

}
