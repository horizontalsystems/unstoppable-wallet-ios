import UIKit
import GrouviActionSheet
import SnapKit

class BackupButtonItemView: BaseActionItemView {

    override var item: BackupButtonItem? { return _item as? BackupButtonItem }

    var button = RespondButton()

    override func initView() {
        super.initView()

        addSubview(button)
        button.cornerRadius = BackupConfirmationTheme.cornerRadius
        button.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupConfirmationTheme.smallMargin)
            maker.top.equalToSuperview().offset(BackupConfirmationTheme.buttonTopMargin)
            maker.trailing.equalToSuperview().offset(-BackupConfirmationTheme.smallMargin)
            maker.height.equalTo(BackupConfirmationTheme.buttonHeight)
        }
    }

    override func updateView() {
        super.updateView()
        if let item = item {
            button.backgrounds = item.backgroundStyle
            button.textColors = item.textStyle
            button.titleLabel.text = item.title
            button.onTap = item.onTap
            button.state = item.isActive ? .active : .disabled
        }
    }

}
