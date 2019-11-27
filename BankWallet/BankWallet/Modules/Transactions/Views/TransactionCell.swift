import UIKit
import UIExtensions
import SnapKit

class TransactionCell: AppCell {
    private let highlightBackground = UIView()

    private let inOutImageView = UIImageView()

    private let dateLabel = UILabel()

    private let processingView = TransactionProcessingView()
    private let completedView = TransactionCompletedView()
    private let failedView = TransactionFailedView()

    private let currencyAmountLabel = UILabel()
    private let lockImageView = UIImageView()
    private let amountLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .crypto_Dark_White

        highlightBackground.backgroundColor = .cryptoSteel20
        highlightBackground.alpha = 0
        contentView.addSubview(highlightBackground)
        highlightBackground.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        contentView.addSubview(inOutImageView)
        inOutImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin3x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }
        inOutImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        inOutImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        dateLabel.font = .appBody
        dateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(inOutImageView.snp.trailing).offset(CGFloat.margin3x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        currencyAmountLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        currencyAmountLabel.textAlignment = .right
        contentView.addSubview(currencyAmountLabel)
        currencyAmountLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.dateLabel.snp.trailing).offset(CGFloat.margin3x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        lockImageView.image = UIImage(named: "Transaction Lock Icon")
        contentView.addSubview(lockImageView)
        lockImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(currencyAmountLabel.snp.trailing)
            maker.trailing.equalTo(contentView.snp.trailingMargin)
            maker.top.equalToSuperview().inset(CGFloat.margin4x)
            maker.size.equalTo(0)
        }
        lockImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        amountLabel.font = .appSubhead2
        amountLabel.textAlignment = .right
        contentView.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().offset(-CGFloat.margin3x)
            maker.trailing.equalTo(contentView.snp.trailingMargin)
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

        contentView.addSubview(failedView)
        failedView.snp.makeConstraints { maker in
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

        dateLabel.textColor = .crypto_Silver_Black
        currencyAmountLabel.textColor = item.incoming ? .appRemus : .appJacob
        amountLabel.textColor = .cryptoGray

        dateLabel.text = DateHelper.instance.formatTransactionDate(from: item.date).uppercased()
        amountLabel.text = ValueFormatter.instance.format(coinValue: item.coinValue, fractionPolicy: .threshold(high: 0.01, low: 0))

        inOutImageView.image = item.incoming ? UIImage(named: "Transaction In Icon") : UIImage(named: "Transaction Out Icon")

        if let value = item.currencyValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.01)) {
            currencyAmountLabel.text = formattedValue
        } else {
            currencyAmountLabel.text = nil
        }

        if item.lockInfo != nil {
            lockImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(currencyAmountLabel.snp.trailing).offset(CGFloat.margin1x)
                maker.trailing.equalTo(contentView.snp.trailingMargin)
                maker.top.equalToSuperview().inset(CGFloat.margin4x)
            }
        } else {
            lockImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(currencyAmountLabel.snp.trailing)
                maker.trailing.equalTo(contentView.snp.trailingMargin)
                maker.top.equalToSuperview().inset(CGFloat.margin4x)
                maker.size.equalTo(0)
            }
        }

        switch status {
        case .failed:
            failedView.isHidden = false

            processingView.stopAnimating()
            processingView.isHidden = true
            completedView.isHidden = true

        case .pending:
            processingView.bind(incoming: item.incoming, progress: 0)
            processingView.startAnimating()
            processingView.isHidden = false

            completedView.isHidden = true
            failedView.isHidden = true

        case .processing(let progress):
            processingView.bind(incoming: item.incoming, progress: progress)
            processingView.startAnimating()
            processingView.isHidden = false

            completedView.isHidden = true
            failedView.isHidden = true

        case .completed:
            completedView.bind(date: item.date)
            completedView.isHidden = false

            processingView.stopAnimating()
            processingView.isHidden = true
            failedView.isHidden = true
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
