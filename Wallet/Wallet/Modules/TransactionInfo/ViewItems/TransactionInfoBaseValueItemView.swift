import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionInfoBaseValueItemView: BaseActionItemView {

    var titleLabel = UILabel()
    var statusLabel = UILabel()
    var statusImageView = UIImageView()

    override var item: TransactionInfoBaseValueItem? { return _item as? TransactionInfoBaseValueItem
    }

    override func initView() {
        super.initView()
        titleLabel.font = TransactionInfoTheme.usualFont
        titleLabel.textColor = TransactionInfoTheme.usualColor
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        statusLabel.font = TransactionInfoTheme.usualFont
        statusLabel.textColor = TransactionInfoTheme.usualColor
        addSubview(statusLabel)
        statusLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
        }

        addSubview(statusImageView)
        statusImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(self.statusLabel.snp.leading).offset(-TransactionInfoTheme.middleMargin)
            maker.size.equalTo(TransactionInfoTheme.statusImageSize)
        }

    }

    override func updateView() {
        super.updateView()
        titleLabel.text = item?.title
        statusLabel.text = item?.value
        statusImageView.image = item?.valueImage
    }

}
