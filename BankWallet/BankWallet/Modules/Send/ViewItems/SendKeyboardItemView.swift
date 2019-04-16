import UIKit
import ActionSheet
import SnapKit

class SendKeyboardItemView: BaseActionItemView {
    private let numpad = NumPad(style: .decimal)

    override var item: SendKeyboardItem? { return _item as? SendKeyboardItem }

    override func initView() {
        super.initView()

        numpad.numPadDelegate = item
        addSubview(numpad)
        numpad.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: SendTheme.keyboardTopMargin, left: SendTheme.keyboardSideMargin, bottom: SendTheme.keyboardBottomMargin, right: SendTheme.keyboardSideMargin))
        }
    }

}
