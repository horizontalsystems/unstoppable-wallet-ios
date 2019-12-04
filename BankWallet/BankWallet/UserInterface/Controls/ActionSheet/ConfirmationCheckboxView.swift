import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class ConfirmationCheckboxView: BaseActionItemView {
    static let checkboxSize: CGFloat = 24

    var checkBox = UIImageView()
    var descriptionLabel = UILabel()

    override var item: ConfirmationCheckboxItem? { return _item as? ConfirmationCheckboxItem }

    override func initView() {
        super.initView()
        addSubview(checkBox)
        checkBox.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(CGFloat.margin6x)
            maker.size.equalTo(ConfirmationCheckboxView.checkboxSize)
        }

        updateCheckBox()

        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.checkBox.snp.trailing).offset(CGFloat.margin4x)
            maker.top.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.attributedText = item?.descriptionText
    }

    func updateCheckBox() {
        if let item = item {
            checkBox.image = item.checked ? UIImage(named: "Checkbox Checked") : UIImage(named: "Checkbox Unchecked")
        }
    }

    override func updateView() {
        super.updateView()

        updateCheckBox()
    }

}
