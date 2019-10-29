import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionStatusItemView: BaseActionItemView {
    let titleLabel = UILabel()
    let statusTextLabel = UILabel()
    let iconImageView = UIImageView()
    let barsProgressView = BarsProgressView(barWidth: TransactionInfoTheme.barsProgressBarWidth, color: TransactionInfoTheme.barsProgressColor, inactiveColor: TransactionInfoTheme.barsProgressInactiveColor)

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

        statusTextLabel.font = TransactionInfoTheme.statusTextFont
        addSubview(statusTextLabel)
        statusTextLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(self.iconImageView.snp.leading).offset(-TransactionInfoTheme.smallMargin)
        }

        addSubview(barsProgressView)
        barsProgressView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
            maker.height.equalTo(TransactionInfoTheme.barsProgressHeight)
        }

        barsProgressView.set(barsCount: AppTheme.progressStepsCount)
    }

    override func updateView() {
        super.updateView()

        titleLabel.text = item?.title
        statusTextLabel.text = item?.statusText
        statusTextLabel.textColor = item?.statusColor ?? TransactionInfoTheme.statusTextColor

        if let icon = item?.icon {
            iconImageView.isHidden = false
            iconImageView.image = icon
        } else {
            iconImageView.isHidden = true
        }

        if let progress = item?.progress {
            barsProgressView.isHidden = false
            barsProgressView.filledCount = Int(Double(AppTheme.progressStepsCount) * progress)
        } else {
            barsProgressView.isHidden = true
        }
    }

}
