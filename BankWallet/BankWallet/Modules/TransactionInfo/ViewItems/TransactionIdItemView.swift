import UIKit
import ActionSheet
import SnapKit

class TransactionIdItemView: BaseActionItemView {
    private let titleLabel = UILabel()
    private let hashView = HashView()

    override var item: TransactionIdItem? { return _item as? TransactionIdItem }

    override func initView() {
        super.initView()

        backgroundColor = TransactionInfoTheme.itemBackground

        titleLabel.font = TransactionInfoTheme.itemTitleFont
        titleLabel.textColor = TransactionInfoTheme.itemTitleColor
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.text = "tx_info.transaction_id".localized

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

        hashView.bind(value: item?.value, showExtra: .hash, onTap: item?.onHashTap)
    }

}
