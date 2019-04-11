import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionFromToHashItemView: BaseActionItemView {

    var titleLabel = UILabel()
    let hashView = TransactionInfoDescriptionView()

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
            maker.height.equalTo(TransactionInfoTheme.hashButtonHeight)
        }
    }

    override func updateView() {
        super.updateView()
        titleLabel.text = item?.title
        hashView.bind(value: item?.value, font: TransactionInfoTheme.itemValueFont, color: TransactionInfoTheme.itemValueColor, showExtra: .icon, onTap: item?.onHashTap)
    }

}
