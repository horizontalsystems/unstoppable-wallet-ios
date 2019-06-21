import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TextSelectItemView: BaseActionItemView {

    var descriptionLabel = UILabel()

    override var item: TextSelectItem? { return _item as? TextSelectItem }

    override func initView() {
        super.initView()
        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
        descriptionLabel.font = AppTheme.actionSheetTextSelectFont
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = item?.text
    }

    func updateSelected() {
        if let item = item {
            descriptionLabel.textColor = item.selected ? AppTheme.actionSheetTextSelectHighlightColor : AppTheme.actionSheetTextSelectDefaultColor
        }
    }

    override func updateView() {
        super.updateView()

        updateSelected()
    }

}
