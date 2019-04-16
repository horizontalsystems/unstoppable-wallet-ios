import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionValueItemView: BaseActionItemView {

    var titleLabel = UILabel()
    var valueLabel = UILabel()

    override var item: TransactionValueItem? { return _item as? TransactionValueItem }

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

        valueLabel.font = TransactionInfoTheme.itemValueFont
        valueLabel.textColor = TransactionInfoTheme.itemValueColor
        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(TransactionInfoTheme.largeMargin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
        }
    }

    override func updateView() {
        super.updateView()

        titleLabel.text = item?.title
        valueLabel.text = item?.value
    }

}
