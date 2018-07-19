import UIKit
import GrouviActionSheet
import SnapKit

class DepositButtonItemView: BaseButtonItemView {

    override var item: DepositButtonItem? { return _item as? DepositButtonItem }

    override func initView() {
        super.initView()

        button.cornerRadius = DepositTheme.cornerRadius
        button.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(DepositTheme.shareButtonSideMargin)
            maker.top.equalToSuperview().offset(DepositTheme.shareButtonTopMargin)
            maker.trailing.equalToSuperview().offset(-DepositTheme.shareButtonSideMargin)
            maker.height.equalTo(DepositTheme.shareButtonHeight)
        }
    }

}
