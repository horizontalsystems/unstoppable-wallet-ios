import UIKit
import GrouviActionSheet

class SendButtonItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return ButtonTheme.yellowBackgroundOnWhiteBackgroundDictionary }
    override var textStyle: RespondButton.Style { return ButtonTheme.textColorOnWhiteBackgroundDictionary }
    override var title: String { return "send".localized }

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onTap: @escaping (() -> ())) {
        super.init(cellType: SendButtonItemView.self, tag: tag, hidden: hidden, required: required)

        self.onTap = onTap
        height = SendTheme.sendButtonItemHeight
    }

}
