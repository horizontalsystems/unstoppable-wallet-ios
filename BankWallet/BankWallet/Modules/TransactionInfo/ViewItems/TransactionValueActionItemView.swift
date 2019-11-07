import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionValueActionItemView: BaseActionItemView {

    let titleLabel = UILabel()
    let valueLabel = UILabel()
    let actionButton = UIButton()

    override var item: TransactionValueActionItem? { _item as? TransactionValueActionItem }

    override func initView() {
        super.initView()

        backgroundColor = TransactionInfoTheme.itemBackground

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(actionButton)

        titleLabel.font = .appSubhead2
        titleLabel.textColor = .cryptoGray
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        valueLabel.font = .appSubhead1
        valueLabel.textColor = .appLeah
        valueLabel.textAlignment = .right
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(CGFloat.margin8x)
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(actionButton.snp.leading)
        }

        actionButton.addTarget(self, action: #selector(onActionClicked), for: .touchUpInside)
        actionButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.bottom.equalToSuperview()
            maker.width.equalTo(0)
        }
    }

    @objc func onActionClicked() {
        item?.onTap?()
    }

    override func updateView() {
        super.updateView()

        titleLabel.text = item?.title
        valueLabel.text = item?.value

        if let iconName = item?.iconName {
            actionButton.setImage(UIImage(named: iconName)?.tinted(with: .appJacob), for: .normal)
            actionButton.snp.updateConstraints { maker in
                maker.trailing.equalToSuperview()
                maker.width.equalTo(24 + CGFloat.margin4x + CGFloat.margin2x)
            }
        } else {
            actionButton.snp.updateConstraints { maker in
                maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
                maker.width.equalTo(0)
            }
        }
    }

}
