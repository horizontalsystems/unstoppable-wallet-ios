import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionValueActionItemView: BaseActionItemView {

    let titleLabel = UILabel()
    let valueLabel = UILabel()

    override var item: TransactionValueActionItem? { _item as? TransactionValueActionItem }

    override func initView() {
        super.initView()

        backgroundColor = .appLawrence

        addSubview(titleLabel)
        addSubview(valueLabel)

        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        titleLabel.font = .appSubhead2
        titleLabel.textColor = .cryptoGray
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(CGFloat.margin8x)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        valueLabel.font = .appSubhead1
        valueLabel.textColor = .appLeah
        valueLabel.textAlignment = .right
    }

    override func updateView() {
        super.updateView()

        titleLabel.text = item?.title
        valueLabel.text = item?.value
    }

}
