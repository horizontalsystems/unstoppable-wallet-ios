import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class BackupCheckboxView: BaseActionItemView {

    var checkBox = UIImageView()
    var descriptionLabel = UILabel()

    override var item: BackupCheckboxItem? { return _item as? BackupCheckboxItem }

    override func initView() {
        super.initView()
        updateCheckBox()
        addSubview(checkBox)
        checkBox.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(BackupConfirmationTheme.bigMargin)
            maker.width.height.equalTo(BackupConfirmationTheme.checkboxSize)
        }
        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.checkBox.snp.trailing).offset(BackupConfirmationTheme.smallMargin)
            maker.top.equalToSuperview().offset(BackupConfirmationTheme.bigMargin)
            maker.trailing.equalToSuperview().offset(-BackupConfirmationTheme.bigMargin)
        }
        descriptionLabel.numberOfLines = 0
        descriptionLabel.attributedText = item?.descriptionText
    }

    func updateCheckBox() {
        if let item = item {
            checkBox.image = item.checked ? UIImage(named: "Checkbox Checked")! : UIImage(named: "Checkbox Unchecked")!
        }
    }

    override func updateView() {
        super.updateView()

        updateCheckBox()
    }

}
