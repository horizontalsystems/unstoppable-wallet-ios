import UIKit
import ActionSheet
import SnapKit

class AlertButtonItemView: BaseButtonItemView {

    override func initView() {
        super.initView()

        button.cornerRadius = .cornerRadius2x
        button.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(item?.insets.left ?? CGFloat.margin4x)
            maker.top.equalToSuperview().offset(item?.insets.top ?? CGFloat.margin8x)
            maker.trailing.equalToSuperview().offset(-(item?.insets.right ?? CGFloat.margin4x))
            maker.height.equalTo(CGFloat.heightButton)
        }
    }

}
