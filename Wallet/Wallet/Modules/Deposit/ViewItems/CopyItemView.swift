import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class CopyItemView: BaseActionItemView {

    var copyButton = RespondButton()

    override var item: CopyItem? { return _item as? CopyItem }

    override func initView() {
        super.initView()
        copyButton.textColors = [RespondButton.State.active: DepositTheme.copyTextColor, RespondButton.State.selected: DepositTheme.copyTextSelectedColor]
        copyButton.titleLabel.text = "alert.copy".localized
        addSubview(copyButton)
        copyButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    override func updateView() {
        super.updateView()
        copyButton.onTap = item?.onCopy
    }

}
