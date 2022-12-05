import UIKit
import SnapKit

class NonStandardPhraseView: TitledHighlightedDescriptionView {
    private static var descriptionText: String { "restore.warning.non_standard_phrase.description".localized }
    private static var moreInfoText: String { "restore.warning.non_standard_phrase.more_info".localized }
    static var fullText: String { [descriptionText, moreInfoText].joined(separator: "\n\n") }

    override public init() {
        super.init()

        titleIcon = UIImage(named: "warning_2_20")?.withTintColor(.themeJacob)
        title = "note".localized
        titleColor = .themeJacob

        let attributedText = NSMutableAttributedString(string: Self.fullText, attributes: [.font: Self.font, .foregroundColor: UIColor.themeBran])
        attributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.double, range: attributedText.mutableString.range(of: Self.moreInfoText))

        label.attributedText = attributedText
        label.textColor = .themeBran
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func viewHeight(containerWidth: CGFloat) -> CGFloat {
        guard !isHidden else {
            return 0
        }

        return NonStandardPhraseView.height(containerWidth: containerWidth, text: Self.fullText)
    }
}

extension NonStandardPhraseView {

    override public class func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * sidePadding, font: font)
        return verticalPadding + 20 + textHeight + 2 * verticalPadding
    }

}
