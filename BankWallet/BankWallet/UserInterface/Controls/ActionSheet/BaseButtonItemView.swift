import UIKit
import GrouviActionSheet
import SnapKit

class BaseButtonItemView: BaseActionItemView {
    override var item: BaseButtonItem? { return _item as? BaseButtonItem }
    var button = RespondButton()

    override func initView() {
        super.initView()

        addSubview(button)
    }

    override func updateView() {
        super.updateView()
        if let item = item {
            button.backgrounds = item.backgroundStyle
            button.textColors = item.textStyle
            button.titleLabel.text = item.title
            button.onTap = item.onTap
            button.state = item.isActive ? .active : .disabled
        }
    }

}
