import UIKit
import GrouviActionSheet

class SendButtonItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return ButtonTheme.yellowBackgroundOnWhiteBackgroundDictionary }
    override var textStyle: RespondButton.Style { return ButtonTheme.textColorOnWhiteBackgroundDictionary }
    override var title: String { return "send".localized }

    var updateButtonTopConstraint: ((CGFloat) -> ())?

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onTap: @escaping (() -> ())) {
        super.init(cellType: SendButtonItemView.self, tag: tag, hidden: hidden, required: required)

        self.onTap = onTap
        height = SendTheme.sendButtonItemHeight
    }

    override func changeHeight(for: CGFloat) -> Bool {
        if `for` >= SendTheme.sendButtonItemHeight {
            height = SendTheme.sendButtonItemHeight
        } else {
            height = SendTheme.sendButtonItemHeightShrink
        }
        updateButtonTopConstraint?(SendTheme.sendButtonTopMarginShrink)
        return true
    }
}
