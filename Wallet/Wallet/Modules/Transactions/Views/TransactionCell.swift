import UIKit
import GrouviExtensions
import SnapKit

class TransactionCell: UITableViewCell {
    var highlightBackground = UIView()

    var dateLabel = UILabel()
    var timeLabel = UILabel()

    var statusImageView = UIImageView()

    var amountLabel = UILabel()
    var fiatAmountLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        highlightBackground.backgroundColor = TransactionsTheme.cellHighlightBackgroundColor
        highlightBackground.alpha = 0
        contentView.addSubview(highlightBackground)
        highlightBackground.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        dateLabel.font = TransactionsTheme.dateLabelFont
        dateLabel.textColor = TransactionsTheme.dateLabelTextColor
        contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(self.layoutMargins.left * 2)
            maker.top.equalToSuperview().offset(TransactionsTheme.cellMediumMargin)
        }
        timeLabel.font = TransactionsTheme.timeLabelFont
        timeLabel.textColor = TransactionsTheme.timeLabelTextColor
        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(self.layoutMargins.left * 2)
            maker.top.equalTo(self.dateLabel.snp.bottom).offset(TransactionsTheme.cellSmallMargin)
        }

        contentView.addSubview(statusImageView)
        statusImageView.snp.makeConstraints { maker in
            maker.size.equalTo(TransactionsTheme.statusImageViewSize)
            maker.leading.equalTo(self.timeLabel.snp.trailing).offset(TransactionsTheme.cellMilliMargin)
            maker.centerY.equalTo(self.timeLabel)
        }


        amountLabel.font = TransactionsTheme.amountLabelFont
        contentView.addSubview(amountLabel)
        amountLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        amountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        amountLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.dateLabel.snp.trailing).offset(TransactionsTheme.cellMediumMargin)
            maker.top.equalToSuperview().offset(TransactionsTheme.cellMediumMargin)
            maker.trailing.equalToSuperview().offset(-self.layoutMargins.left * 2)
        }

        fiatAmountLabel.font = TransactionsTheme.fiatAmountLabelFont
        fiatAmountLabel.textColor = TransactionsTheme.fiatAmountLabelColor
        fiatAmountLabel.textAlignment = .right
        contentView.addSubview(fiatAmountLabel)
        fiatAmountLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.timeLabel.snp.trailing).offset(TransactionsTheme.cellMediumMargin)
            maker.top.equalTo(self.amountLabel.snp.bottom).offset(TransactionsTheme.cellMicroMargin)
            maker.trailing.equalToSuperview().offset(-self.layoutMargins.left * 2)
        }

        let separatorView = UIView()
        separatorView.backgroundColor = TransactionsTheme.separatorColor
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: TransactionRecordViewItem) {
        dateLabel.text = (item.date.map { DateHelper.instance.formatTransactionDate(from: $0) })?.uppercased()
        timeLabel.text = item.date.map { DateHelper.instance.formatTransactionTime(from: $0) }

        amountLabel.textColor = item.incoming ? TransactionsTheme.incomingTextColor : TransactionsTheme.outgoingTextColor
        amountLabel.text = (item.incoming ? "+ " : "- ") + CoinValueHelper.formattedAmount(for: item.amount)

        if let fiatAmount = (item.currencyAmount.map { CurrencyHelper.instance.formattedApproximateValue(for: $0) }) {
            fiatAmountLabel.text = "~ " + fiatAmount!
        } else {
            fiatAmountLabel.text = "n/a"
        }

        statusImageView.image = item.status == .pending ? UIImage(named: "Transaction Processing Icon") : nil
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
