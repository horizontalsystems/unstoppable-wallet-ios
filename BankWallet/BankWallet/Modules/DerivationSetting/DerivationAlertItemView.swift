import UIKit
import ActionSheet
import SnapKit
import ThemeKit

class DerivationAlertItemView: BaseActionItemView {
    private let leftView = DoubleLineCellView()
    private let rightView = CheckmarkCellView()

    override var item: DerivationAlertItem? { _item as? DerivationAlertItem }

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

        leftView.bind(title: item?.derivation.title, subtitle: item?.derivation.description)

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
