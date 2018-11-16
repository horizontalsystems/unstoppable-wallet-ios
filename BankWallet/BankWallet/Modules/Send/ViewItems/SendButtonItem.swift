import UIKit
import GrouviActionSheet

class SendButtonItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return ButtonTheme.yellowBackgroundOnWhiteBackgroundDictionary }
    override var textStyle: RespondButton.Style { return ButtonTheme.textColorOnWhiteBackgroundDictionary }
    override var title: String { return "send".localized }

//    var updateButtonBottomConstraint: ((CGFloat) -> ())?

    var onClicked: (() -> ())?

    init(tag: Int) {
        super.init(cellType: SendButtonItemView.self, tag: tag, required: true)

        self.onTap = { [weak self] in
            self?.onClicked?()
        }
        height = SendTheme.sendHeight
    }

//    override func changeHeight(for: CGFloat) -> Bool {
//        if `for` >= SendTheme.sendButtonItemHeight {
//            height = SendTheme.sendButtonItemHeight
//        } else {
//            height = SendTheme.sendButtonItemHeightShrink
//        }
//        updateButtonBottomConstraint?(-SendTheme.sendButtonBottomMarginShrink)
//        return true
//    }

}
