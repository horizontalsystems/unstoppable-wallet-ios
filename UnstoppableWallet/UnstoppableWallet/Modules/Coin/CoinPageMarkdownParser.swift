import UIKit
import Down

class CoinPageMarkdownParser {

    let fonts = StaticFontCollection(
            heading1: .title2,
            heading2: .title3,
            heading3: .subhead1,
            body: .subhead2
    )

    let colors = StaticColorCollection(
            heading1: .themeLeah,
            heading2: .themeJacob,
            heading3: .themeBran,
            body: .themeGray
    )

    let paragraphStyles: StaticParagraphStyleCollection = {
        var paragraphStyles = StaticParagraphStyleCollection()

        let headingParagraphStyle = NSMutableParagraphStyle()
        headingParagraphStyle.paragraphSpacingBefore = .margin12
        headingParagraphStyle.paragraphSpacing = .margin12

        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.paragraphSpacingBefore = .margin12
        bodyParagraphStyle.paragraphSpacing = .margin12

        paragraphStyles.heading1 = headingParagraphStyle
        paragraphStyles.heading2 = headingParagraphStyle
        paragraphStyles.heading3 = headingParagraphStyle
        paragraphStyles.body = bodyParagraphStyle

        return paragraphStyles
    }()

    func attributedString(from string: String) throws -> NSAttributedString {
        let down = Down(markdownString: string)

        let listItemOptions = ListItemOptions(maxPrefixDigits: 1, spacingAfterPrefix: .margin8, spacingAbove: .margin12, spacingBelow: .margin12)

        let configuration = DownStylerConfiguration(
                fonts: fonts,
                colors: colors,
                paragraphStyles: paragraphStyles,
                listItemOptions: listItemOptions
        )

        let styler = DownStyler(configuration: configuration)
        return try down.toAttributedString(styler: styler)
    }

}
