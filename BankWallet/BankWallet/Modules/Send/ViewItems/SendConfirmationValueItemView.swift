import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class SendConfirmationValueItemView: BaseActionItemView {
    let titleLabel = UILabel()
    let valueLabel = UILabel()

    override var item: SendConfirmationValueItem? { return _item as? SendConfirmationValueItem }

    override func initView() {
        super.initView()

        titleLabel.font = SendTheme.valueFont
        titleLabel.textColor = SendTheme.valueColor
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(SendTheme.smallMargin)
            maker.leading.equalToSuperview().offset(SendTheme.margin)
        }

        valueLabel.font = SendTheme.valueFont
        valueLabel.textColor = SendTheme.valueColor
        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(self.titleLabel.snp.centerY)
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(SendTheme.margin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
        }
    }

    override func updateView() {
        super.updateView()

        titleLabel.text = (item?.title).map { "\($0):" }
        valueLabel.text = item?.value
    }

}
