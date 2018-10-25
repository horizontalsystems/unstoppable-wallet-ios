import UIKit
import GrouviActionSheet
import SnapKit

class DepositShareButtonItemView: BaseButtonItemView {

    override var item: DepositShareButtonItem? { return _item as? DepositShareButtonItem
    }

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
