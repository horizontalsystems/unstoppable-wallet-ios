import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionFromToHashItemView: BaseActionItemView {

    var titleLabel = UILabel()
    let hashView = HashView()

    override var item: TransactionFromToHashItem? { return _item as? TransactionFromToHashItem
    }

    override func initView() {
        super.initView()

        backgroundColor = TransactionInfoTheme.itemBackground

        titleLabel.font = TransactionInfoTheme.itemTitleFont
        titleLabel.textColor = TransactionInfoTheme.itemTitleColor
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        addSubview(hashView)
        hashView.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(TransactionInfoTheme.hashViewMargin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
        }
    }

    override func updateView() {
        super.updateView()
        titleLabel.text = item?.title
        hashView.bind(value: item?.value, showExtra: .icon, onTap: item?.onHashTap)
    }

}
