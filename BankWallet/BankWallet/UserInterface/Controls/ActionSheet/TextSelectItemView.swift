import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TextSelectItemView: BaseActionItemView {

    var titleLabel = UILabel()

    override var item: TextSelectItem? { return _item as? TextSelectItem }

    override func initView() {
        super.initView()
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
        titleLabel.font = item?.font ?? AppTheme.alertCellFont
        titleLabel.numberOfLines = 0
        titleLabel.text = item?.text
    }

    func updateSelected() {
        if let item = item {
            titleLabel.textColor = item.selected ? AppTheme.alertCellHighlightColor : item.color
        }
    }

    override func updateView() {
        super.updateView()

        updateSelected()
    }

}
