import UIKit
import ActionSheet

class SendButtonItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return ButtonTheme.yellowBackgroundDictionary }
    override var textStyle: RespondButton.Style { return ButtonTheme.textColorDictionary }
    override var title: String { return buttonTitle }

    let buttonTitle: String
    var onClicked: (() -> ())?

    init(buttonTitle: String, tag: Int) {
        self.buttonTitle = buttonTitle

        super.init(cellType: SendButtonItemView.self, tag: tag, required: true)

        self.onTap = { [weak self] in
            self?.onClicked?()
        }
        height = SendTheme.sendHeight
        showSeparator = false
    }

}
