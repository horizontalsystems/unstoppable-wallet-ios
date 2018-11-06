import UIKit
import GrouviActionSheet
import SnapKit

class DepositCopyButtonItemView: BaseButtonItemView {

    override var item: DepositCopyButtonItem? { return _item as? DepositCopyButtonItem
    }

    override func initView() {
        super.initView()

        button.cornerRadius = DepositTheme.cornerRadius
        button.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(DepositTheme.copyButtonSideMargin)
            maker.top.equalToSuperview().offset(DepositTheme.copyButtonTopMargin)
            maker.trailing.equalToSuperview().offset(-DepositTheme.copyButtonSideMargin)
            maker.height.equalTo(DepositTheme.copyButtonHeight)
        }
    }

}
