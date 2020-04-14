import UIKit
import ActionSheet
import SnapKit
import ThemeKit

class RadioItemView: BaseActionItemView {
    private let leftView = DoubleLineCellView()
    private let rightView = CheckmarkCellView()

    override var item: RadioItem? { _item as? RadioItem }

    override func initView() {
        super.initView()

        addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.trailing.top.bottom.equalToSuperview()
            maker.leading.equalTo(leftView.snp.trailing)
        }

        leftView.bind(title: item?.title, subtitle: item?.subtitle)

        updateSelected()
    }

    private func updateSelected() {
        if let item = item {
            rightView.bind(visible: item.selected)
        }
    }

    override func updateView() {
        super.updateView()

        updateSelected()
    }

}
