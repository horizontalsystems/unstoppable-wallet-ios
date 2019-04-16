import UIKit
import ActionSheet

class SendKeyboardItem: BaseActionItem {
    var addLetter: ((String) -> ())?
    var removeLetter: (() -> ())?

    init(tag: Int) {
        super.init(cellType: SendKeyboardItemView.self, tag: tag, required: true)

        height = SendTheme.keyboardHeight + SendTheme.keyboardTopMargin + SendTheme.keyboardBottomMargin
        showSeparator = false
    }

}

extension SendKeyboardItem: NumPadDelegate {

    func numPadDidClick(digit: String) {
        addLetter?(digit)
    }

    func numPadDidClickBackspace() {
        removeLetter?()
    }

}
