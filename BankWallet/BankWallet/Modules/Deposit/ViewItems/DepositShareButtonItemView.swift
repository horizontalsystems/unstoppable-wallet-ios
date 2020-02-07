import UIKit
import ActionSheet
import SnapKit

class DepositShareButtonItemView: BaseButtonItemView {

    override var item: DepositShareButtonItem? {
        _item as? DepositShareButtonItem
    }

    override func initView() {
        super.initView()

        button.cornerRadius = .cornerRadius2x
        button.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }
    }

}
