import UIKit
import GrouviActionSheet
import SnapKit

class BackupButtonItemView: BaseButtonItemView {

    override var item: BackupButtonItem? { return _item as? BackupButtonItem }

    override func initView() {
        super.initView()

        button.cornerRadius = BackupConfirmationTheme.cornerRadius
        button.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupConfirmationTheme.smallMargin)
            maker.top.equalToSuperview().offset(BackupConfirmationTheme.buttonTopMargin)
            maker.trailing.equalToSuperview().offset(-BackupConfirmationTheme.smallMargin)
            maker.height.equalTo(BackupConfirmationTheme.buttonHeight)
        }
    }

}
