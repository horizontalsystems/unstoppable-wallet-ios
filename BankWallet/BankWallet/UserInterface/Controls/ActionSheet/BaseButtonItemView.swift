import UIKit
import ActionSheet
import SnapKit

class BaseButtonItemView: BaseActionItemView {
    override var item: BaseButtonItem? { _item as? BaseButtonItem }
    var button: UIButton

    required init(item: BaseActionItem) {
        button = (item as? BaseButtonItem)?.createButton ?? UIButton()

        super.init(item: item)

        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init with coder is not available")
    }

    override func initView() {
        super.initView()

        addSubview(button)
    }

    override func updateView() {
        super.updateView()
        if let item = item {
            button.setTitle(item.title, for: .normal)
            button.isEnabled = item.isEnabled
        }
    }

    @objc private func onTap() {
        item?.onTap?()
    }

}
