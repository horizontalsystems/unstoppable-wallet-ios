import UIKit
import GrouviExtensions

public class SectionLabelView: UITableViewHeaderFooterView {
    private static let font = UIFont.systemFont(ofSize: 13)

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(title: String, topMargin: CGFloat) {
        label.text = title
        topConstraint.constant = topMargin
    }

    static func height(forContainerWidth containerWidth: CGFloat, text: String, additionalMargins: CGFloat) -> CGFloat {
        return ceil(text.heightt(forContainerWidth: containerWidth - LayoutHelper.instance.contentMarginWidth, font: font) + additionalMargins)
    }

}
