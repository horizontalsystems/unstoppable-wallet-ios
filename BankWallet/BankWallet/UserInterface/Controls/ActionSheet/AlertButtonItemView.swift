import UIKit
import ActionSheet
import SnapKit

class AlertButtonItemView: BaseButtonItemView {

    override func initView() {
        super.initView()

        button.cornerRadius = ConfirmationTheme.cornerRadius
        button.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(item?.insets.left ?? ConfirmationTheme.smallMargin)
            maker.top.equalToSuperview().offset(item?.insets.top ?? ConfirmationTheme.buttonTopMargin)
            maker.trailing.equalToSuperview().offset(-(item?.insets.right ?? ConfirmationTheme.smallMargin))
            maker.height.equalTo(ConfirmationTheme.buttonHeight)
        }
    }

}
