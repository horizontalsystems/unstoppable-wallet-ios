import UIKit
import UIExtensions
import SnapKit
import ThemeKit

class TransactionCell: ClaudeThemeCell {
    private let typeIconImageView = UIImageView()
    private let doubleSpendImageView = UIImageView()

    private let dateLabel = UILabel()

    private let processingView = TransactionProcessingView()
    private let completedView = TransactionCompletedView()
    private let failedLabel = UILabel()

    private let currencyAmountLabel = UILabel()
    private let amountLabel = UILabel()

    private let lockImageView = UIImageView()
    private let sentToSelfImageView = UIImageView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let wrapperView = UIView()

        wrapperView.addSubview(typeIconImageView)
        typeIconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin3x)
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
        }
        typeIconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        typeIconImageView.setContentHuggingPriority(.required, for: .horizontal)

        wrapperView.addSubview(doubleSpendImageView)
        doubleSpendImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }
        doubleSpendImageView.image = UIImage(named: "Transaction Double Spend Icon")
        doubleSpendImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        doubleSpendImageView.setContentHuggingPriority(.required, for: .horizontal)
        doubleSpendImageView.isHidden = true

        wrapperView.addSubview(failedLabel)
        failedLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(typeIconImageView.snp.trailing).offset(CGFloat.margin3x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }
        failedLabel.font = .subhead2
        failedLabel.textColor = .themeLucian
        failedLabel.text = "transactions.failed".localized

        wrapperView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(typeIconImageView.snp.trailing).offset(CGFloat.margin3x)
            maker.trailing.lessThanOrEqualToSuperview().inset(CGFloat.margin3x)
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
        }
        dateLabel.font = .body
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)

        wrapperView.addSubview(completedView)
        completedView.snp.makeConstraints { maker in
            maker.leading.equalTo(typeIconImageView.snp.trailing).offset(CGFloat.margin3x)
            maker.trailing.lessThanOrEqualToSuperview().inset(CGFloat.margin3x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        wrapperView.addSubview(processingView)
        processingView.snp.makeConstraints { maker in
            maker.leading.equalTo(typeIconImageView.snp.trailing).offset(CGFloat.margin3x)
            maker.trailing.lessThanOrEqualToSuperview().inset(CGFloat.margin3x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        contentView.addSubview(currencyAmountLabel)
        currencyAmountLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(wrapperView.snp.trailing).offset(CGFloat.margin3x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }
        currencyAmountLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        currencyAmountLabel.textAlignment = .right

        contentView.addSubview(lockImageView)
        lockImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(currencyAmountLabel.snp.trailing).offset(CGFloat.margin3x)
            maker.top.equalToSuperview().inset(CGFloat.margin4x)
            maker.size.equalTo(0)
        }
        lockImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        contentView.addSubview(sentToSelfImageView)
        sentToSelfImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(lockImageView.snp.trailing)
            maker.trailing.equalTo(contentView.snp.trailingMargin)
            maker.top.equalToSuperview().inset(CGFloat.margin4x)
            maker.size.equalTo(0)
        }
        sentToSelfImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        sentToSelfImageView.image = UIImage(named: "Transaction In Icon")

        contentView.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.equalTo(wrapperView.snp.trailing).offset(CGFloat.margin3x)
            maker.trailing.equalTo(contentView.snp.trailingMargin)
        }
        amountLabel.font = .subhead2
        amountLabel.textAlignment = .right
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: TransactionViewItem, first: Bool, last: Bool) {
        super.bind(last: last)

        let status = item.status

        dateLabel.textColor = .themeLeah
        switch item.type {
        case .incoming:
            currencyAmountLabel.textColor = .themeGreenD
            typeIconImageView.image = UIImage(named: "Transaction In Icon")
        case .outgoing, .sentToSelf:
            currencyAmountLabel.textColor = .themeYellowD
            typeIconImageView.image = UIImage(named: "Transaction Out Icon")
        case .approve:
            currencyAmountLabel.textColor = .themeLeah
            typeIconImageView.image = UIImage(named: "Transaction Approve Icon")?.tinted(with: .themeLeah)
        }
        amountLabel.textColor = .themeGray

        dateLabel.text = DateHelper.instance.formatTransactionDate(from: item.date).uppercased()
        amountLabel.text = ValueFormatter.instance.format(coinValue: item.coinValue, fractionPolicy: .threshold(high: 0.01, low: 0))

        doubleSpendImageView.isHidden = item.conflictingTxHash == nil

        if let value = item.currencyValue?.nonZero, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.01)) {
            currencyAmountLabel.text = formattedValue
        } else {
            currencyAmountLabel.text = nil
        }

        if let lockState = item.lockState {
            lockImageView.image = UIImage(named: lockState.locked ? "Transaction Lock Icon" : "Transaction Unlock Icon")
            lockImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(currencyAmountLabel.snp.trailing).offset(CGFloat.margin1x)
                maker.top.equalToSuperview().inset(CGFloat.margin4x)
            }
        } else {
            lockImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(currencyAmountLabel.snp.trailing)
                maker.top.equalToSuperview().inset(CGFloat.margin4x)
                maker.size.equalTo(0)
            }
        }

        if item.type == .sentToSelf {
            sentToSelfImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(lockImageView.snp.trailing).offset(CGFloat.margin1x)
                maker.trailing.equalTo(contentView.snp.trailingMargin)
                maker.top.equalToSuperview().inset(CGFloat.margin4x)
                maker.size.equalTo(16)
            }
        } else {
            sentToSelfImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(lockImageView.snp.trailing)
                maker.trailing.equalTo(contentView.snp.trailingMargin)
                maker.top.equalToSuperview().inset(CGFloat.margin4x)
                maker.size.equalTo(0)
            }
        }

        switch status {
        case .failed:
            failedLabel.isHidden = false

            processingView.stopAnimating()
            processingView.isHidden = true
            completedView.isHidden = true

        case .pending:
            processingView.bind(type: item.type, progress: 0)
            processingView.startAnimating()
            processingView.isHidden = false

            completedView.isHidden = true
            failedLabel.isHidden = true

        case .processing(let progress):
            processingView.bind(type: item.type, progress: progress)
            processingView.startAnimating()
            processingView.isHidden = false

            completedView.isHidden = true
            failedLabel.isHidden = true

        case .completed:
            completedView.bind(date: item.date)
            completedView.isHidden = false

            processingView.stopAnimating()
            processingView.isHidden = true
            failedLabel.isHidden = true
        }
    }

}
