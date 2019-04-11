import UIKit
import GrouviActionSheet
import SnapKit

class DepositShareButtonItemView: BaseButtonItemView {

    override var item: DepositShareButtonItem? { return _item as? DepositShareButtonItem
    }

    override func initView() {
        super.initView()

        button.cornerRadius = DepositTheme.shareButtonCornerRadius
        button.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(DepositTheme.regularMargin)
            maker.top.equalToSuperview().offset(DepositTheme.regularMargin)
            maker.trailing.equalToSuperview().offset(-DepositTheme.regularMargin)
            maker.height.equalTo(DepositTheme.shareButtonHeight)
        }
    }

}
