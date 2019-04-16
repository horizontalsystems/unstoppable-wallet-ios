import UIKit
import ActionSheet
import SnapKit

class AlertButtonItemView: BaseButtonItemView {

    override func initView() {
        super.initView()

        button.cornerRadius = ConfirmationTheme.cornerRadius
        button.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(ConfirmationTheme.smallMargin)
            maker.top.equalToSuperview().offset(ConfirmationTheme.buttonTopMargin)
            maker.trailing.equalToSuperview().offset(-ConfirmationTheme.smallMargin)
            maker.height.equalTo(ConfirmationTheme.buttonHeight)
        }
    }

}
