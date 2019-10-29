import UIKit
import UIExtensions
import SnapKit

class TransactionCell: AppCell {
    var highlightBackground = UIView()

    var inOutImageView = UIImageView()

    var dateLabel = UILabel()

    var pendingView = TransactionPendingView()
    var processingView = TransactionProcessingView()
    var completedView = TransactionCompletedView()

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
            maker.bottom.equalToSuperview().offset(-TransactionsTheme.cellMediumMargin)
            maker.trailing.equalTo(contentView.snp.trailingMargin)
        }

        contentView.addSubview(pendingView)
        pendingView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        pendingView.snp.makeConstraints { maker in
            maker.leading.equalTo(inOutImageView.snp.trailing).offset(CGFloat.margin3x)
            maker.centerY.equalTo(amountLabel)
        }
        contentView.addSubview(processingView)
        processingView.snp.makeConstraints { maker in
            maker.leading.equalTo(inOutImageView.snp.trailing).offset(CGFloat.margin3x)
            maker.centerY.equalTo(amountLabel)
        }
        contentView.addSubview(completedView)
        completedView.snp.makeConstraints { maker in
            maker.leading.equalTo(inOutImageView.snp.trailing).offset(CGFloat.margin3x)
            maker.centerY.equalTo(amountLabel)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: TransactionViewItem, first: Bool, last: Bool) {
        super.bind(last: last)

        let status = item.status

        dateLabel.textColor = status == .pending ? TransactionsTheme.dateLabelTextColor50 : TransactionsTheme.dateLabelTextColor
        let incomingTextColor = status == .pending ? TransactionsTheme.incomingTextColor50 : TransactionsTheme.incomingTextColor
        let outgoingTextColor = status == .pending ? TransactionsTheme.outgoingTextColor50 : TransactionsTheme.outgoingTextColor
        currencyAmountLabel.textColor = item.incoming ? incomingTextColor : outgoingTextColor
        amountLabel.textColor = status == .pending ? TransactionsTheme.fiatAmountLabelColor50 : TransactionsTheme.fiatAmountLabelColor

        dateLabel.text = DateHelper.instance.formatTransactionDate(from: item.date).uppercased()
        amountLabel.text = ValueFormatter.instance.format(coinValue: item.coinValue, fractionPolicy: .threshold(high: 0.01, low: 0))

        inOutImageView.image = item.incoming ? UIImage(named: "Transaction In Icon") : UIImage(named: "Transaction Out Icon")

        if let value = item.currencyValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.01)) {
            currencyAmountLabel.text = formattedValue
        } else {
            currencyAmountLabel.text = nil
        }

        switch status {
        case .pending:
            pendingView.startAnimating()
            pendingView.isHidden = false

            processingView.stopAnimating()
            processingView.isHidden = true
            completedView.isHidden = true

        case .processing(let progress):
            processingView.bind(filledCount: Int(Double(TransactionProcessingView.stepsCount) * progress))
            processingView.startAnimating()
            processingView.isHidden = false

            pendingView.stopAnimating()
            pendingView.isHidden = true
            completedView.isHidden = true

        case .completed:
            completedView.bind(date: item.date)
            completedView.isHidden = false

            pendingView.stopAnimating()
            pendingView.isHidden = true
            processingView.stopAnimating()
            processingView.isHidden = true

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
