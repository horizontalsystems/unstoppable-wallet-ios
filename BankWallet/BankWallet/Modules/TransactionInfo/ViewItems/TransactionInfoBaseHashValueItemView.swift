import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionInfoBaseHashValueItemView: BaseActionItemView {

    var titleLabel = UILabel()
    var valueLabel = UILabel()

    override var item: TransactionInfoBaseHashValueItem? { return _item as? TransactionInfoBaseHashValueItem }

    override func initView() {
        super.initView()
        titleLabel.font = TransactionInfoTheme.usualFont
        titleLabel.textColor = TransactionInfoTheme.usualColor
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        let wrapperView = UIView()
        wrapperView.backgroundColor = TransactionInfoTheme.hashBackground
        wrapperView.borderColor = TransactionInfoTheme.hashWrapperBorderColor
        wrapperView.borderWidth = 1 / UIScreen.main.scale
        wrapperView.cornerRadius = TransactionInfoTheme.hashCornerRadius
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(TransactionInfoTheme.middleMargin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.middleMargin)
            maker.height.equalTo(TransactionInfoTheme.hashBackgroundHeight)
        }

        valueLabel.font = TransactionInfoTheme.usualFont
        valueLabel.textColor = TransactionInfoTheme.hashColor
        valueLabel.lineBreakMode = .byTruncatingMiddle
        wrapperView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalToSuperview().inset(TransactionInfoTheme.middleMargin)
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.middleMargin)
        }
    }

    override func updateView() {
        super.updateView()
        titleLabel.text = item?.title
        valueLabel.text = item?.value
    }

}
