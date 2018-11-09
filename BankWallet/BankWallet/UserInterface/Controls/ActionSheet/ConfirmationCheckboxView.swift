import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class ConfirmationCheckboxView: BaseActionItemView {

    var checkBox = UIImageView()
    var descriptionLabel = UILabel()

    override var item: ConfirmationCheckboxItem? { return _item as? ConfirmationCheckboxItem }

    override func initView() {
        super.initView()
        updateCheckBox()
        addSubview(checkBox)
        checkBox.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(ConfirmationTheme.bigMargin)
            maker.width.height.equalTo(ConfirmationTheme.checkboxSize)
        }
        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.checkBox.snp.trailing).offset(ConfirmationTheme.smallMargin)
            maker.top.equalToSuperview().offset(ConfirmationTheme.bigMargin)
            maker.trailing.equalToSuperview().offset(-ConfirmationTheme.bigMargin)
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
