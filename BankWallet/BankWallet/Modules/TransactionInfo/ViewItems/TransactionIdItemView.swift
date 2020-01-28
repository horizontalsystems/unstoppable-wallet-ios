import UIKit
import ActionSheet
import SnapKit

class TransactionIdItemView: BaseActionItemView {
    private let titleLabel = UILabel()
    private let hashView = HashView()

    override var item: TransactionIdItem? { return _item as? TransactionIdItem }

    override func initView() {
        super.initView()

        backgroundColor = .themeLawrence

        addSubview(titleLabel)
        addSubview(hashView)

        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.font = .subhead2
        titleLabel.textColor = .themeGray
        titleLabel.text = "tx_info.transaction_id".localized

        hashView.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(CGFloat.margin12x)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
    }

    override func updateView() {
        super.updateView()

        hashView.bind(value: item?.value, showExtra: .hash, onTap: item?.onHashTap)
    }

}
