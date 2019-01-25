import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionStatusItemView: BaseActionItemView {
    let titleLabel = UILabel()
    let iconImageView = UIImageView()
    let barsProgressView = BarsProgressView(count: 6, barWidth: TransactionInfoTheme.barsProgressBarWidth, color: TransactionInfoTheme.barsProgressColor, inactiveColor: TransactionInfoTheme.barsProgressInactiveColor)

    override var item: TransactionStatusItem? { return _item as? TransactionStatusItem }

    override func initView() {
        super.initView()

        backgroundColor = TransactionInfoTheme.itemBackground

        titleLabel.font = TransactionInfoTheme.itemTitleFont
        titleLabel.textColor = TransactionInfoTheme.itemTitleColor
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
        }

        addSubview(barsProgressView)
        barsProgressView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
            maker.height.equalTo(TransactionInfoTheme.barsProgressHeight)
        }
    }

    override func updateView() {
        super.updateView()

        titleLabel.text = item?.title

        if let icon = item?.icon {
            iconImageView.isHidden = false
            iconImageView.image = icon
        } else {
            iconImageView.isHidden = true
        }

        if let progress = item?.progress {
            barsProgressView.isHidden = false
            barsProgressView.filledCount = Int(floor(6 * progress))
        } else {
            barsProgressView.isHidden = true
        }
    }

}
