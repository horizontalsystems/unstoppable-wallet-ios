import UIKit
import UIExtensions
import SnapKit

class TransactionCell: AppCell {
    var highlightBackground = UIView()

    var inOutImageView = UIImageView()

    var dateLabel = UILabel()
    var timeLabel = UILabel()

    var pendingImageView = UIImageView()
    var completedImageView = UIImageView()
    var barsProgressView = BarsProgressView(count: AppTheme.progressStepsCount, barWidth: TransactionsTheme.barsProgressBarWidth, color: TransactionsTheme.barsProgressColor, inactiveColor: TransactionsTheme.barsProgressInactiveColor)

    var currencyAmountLabel = UILabel()
    var amountLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = TransactionsTheme.cellBackground

        highlightBackground.backgroundColor = TransactionsTheme.cellHighlightBackgroundColor
        highlightBackground.alpha = 0
        contentView.addSubview(highlightBackground)
        highlightBackground.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        contentView.addSubview(inOutImageView)
        inOutImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(TransactionsTheme.cellMediumMargin)
            maker.top.equalToSuperview().offset(TransactionsTheme.cellMediumMargin)
        }
        inOutImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        inOutImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        dateLabel.font = TransactionsTheme.dateLabelFont
        dateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(inOutImageView.snp.trailing).offset(TransactionsTheme.cellMediumMargin)
            maker.top.equalToSuperview().offset(TransactionsTheme.cellMediumMargin)
        }
        timeLabel.font = TransactionsTheme.timeLabelFont
        timeLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        timeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(inOutImageView.snp.trailing).offset(TransactionsTheme.cellMediumMargin)
            maker.bottom.equalToSuperview().offset(-TransactionsTheme.cellMediumMargin)
        }

        currencyAmountLabel.font = TransactionsTheme.currencyAmountLabelFont
        currencyAmountLabel.textAlignment = .right
        contentView.addSubview(currencyAmountLabel)
        currencyAmountLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.dateLabel.snp.trailing).offset(TransactionsTheme.cellMediumMargin)
            maker.top.equalToSuperview().offset(TransactionsTheme.cellMediumMargin)
            maker.trailing.equalTo(contentView.snp.trailingMargin)
        }

        amountLabel.font = TransactionsTheme.amountLabelFont
        amountLabel.textAlignment = .right
        contentView.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.timeLabel.snp.trailing).offset(TransactionsTheme.cellMediumMargin)
            maker.bottom.equalToSuperview().offset(-TransactionsTheme.cellMediumMargin)
            maker.trailing.equalTo(contentView.snp.trailingMargin)
        }

        pendingImageView.image = UIImage(named: "Transaction Processing Icon")
        pendingImageView.alpha = TransactionsTheme.pendingStatusIconTransparency
        contentView.addSubview(pendingImageView)
        pendingImageView.snp.makeConstraints { maker in
            maker.size.equalTo(TransactionsTheme.statusImageViewSize)
            maker.leading.equalTo(inOutImageView.snp.trailing).offset(TransactionsTheme.cellMediumMargin)
            maker.centerY.equalTo(self.amountLabel)
        }

        completedImageView.image = UIImage(named: "Transaction Success Icon")
        contentView.addSubview(completedImageView)
        completedImageView.snp.makeConstraints { maker in
            maker.size.equalTo(TransactionsTheme.statusImageViewSize)
            maker.leading.equalTo(self.timeLabel.snp.trailing).offset(TransactionsTheme.cellSmallMargin)
            maker.centerY.equalTo(self.amountLabel)
        }

        contentView.addSubview(barsProgressView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: TransactionViewItem, first: Bool, last: Bool) {
        super.bind(last: last)

        dateLabel.textColor = item.status == .pending ? TransactionsTheme.dateLabelTextColor50 : TransactionsTheme.dateLabelTextColor
        timeLabel.textColor = item.status == .pending ? TransactionsTheme.timeLabelTextColor50 : TransactionsTheme.timeLabelTextColor
        timeLabel.textColor = item.status == .pending ? TransactionsTheme.timeLabelTextColor50 : TransactionsTheme.timeLabelTextColor
        let incomingTextColor = item.status == .pending ? TransactionsTheme.incomingTextColor50 : TransactionsTheme.incomingTextColor
        let outgoingTextColor = item.status == .pending ? TransactionsTheme.outgoingTextColor50 : TransactionsTheme.outgoingTextColor
        currencyAmountLabel.textColor = item.incoming ? incomingTextColor : outgoingTextColor
        amountLabel.textColor = item.status == .pending ? TransactionsTheme.fiatAmountLabelColor50 : TransactionsTheme.fiatAmountLabelColor

        dateLabel.text = DateHelper.instance.formatTransactionDate(from: item.date).uppercased()
        timeLabel.text = DateHelper.instance.formatTransactionTime(from: item.date)

        amountLabel.text = ValueFormatter.instance.format(coinValue: item.coinValue, fractionPolicy: .threshold(high: 0.01, low: 0))

        inOutImageView.image = item.incoming ? UIImage(named: "Transaction In Icon") : UIImage(named: "Transaction Out Icon")

        if let value = item.currencyValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.01)) {
            currencyAmountLabel.text = formattedValue
        } else {
            currencyAmountLabel.text = nil
        }

        switch item.status {
        case .pending:
            pendingImageView.isHidden = false
            barsProgressView.isHidden = false
            completedImageView.isHidden = true
            timeLabel.isHidden = true

            barsProgressView.filledCount = 0
        case .processing(let progress):
            pendingImageView.isHidden = true
            barsProgressView.isHidden = false
            completedImageView.isHidden = true
            timeLabel.isHidden = false

            barsProgressView.filledCount = Int(Double(AppTheme.progressStepsCount) * progress)
        case .completed:
            pendingImageView.isHidden = true
            barsProgressView.isHidden = true
            completedImageView.isHidden = false
            timeLabel.isHidden = false
        }

        barsProgressView.snp.remakeConstraints { maker in
            maker.height.equalTo(TransactionsTheme.barsProgressHeight)
            maker.centerY.equalTo(self.amountLabel)

            if self.pendingImageView.isHidden {
                maker.leading.equalTo(self.timeLabel.snp.trailing).offset(TransactionsTheme.cellSmallMargin)
            } else {
                maker.leading.equalTo(self.pendingImageView.snp.trailing).offset(TransactionsTheme.cellSmallMargin)
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.highlightBackground.alpha = highlighted ? 1 : 0
            }
        } else {
            highlightBackground.alpha = highlighted ? 1 : 0
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.highlightBackground.alpha = selected ? 1 : 0
            }
        } else {
            highlightBackground.alpha = selected ? 1 : 0
        }
    }

}
