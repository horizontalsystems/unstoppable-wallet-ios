import UIKit
import UIExtensions
import SnapKit
import ThemeKit
import ComponentKit

class TransactionCell: BaseSelectableThemeCell {
    private let typeIconImageView = UIImageView()

    private let dateLabel = UILabel()

    private let processingView = TransactionProcessingView()
    private let statusView = TransactionStatusView()

    private let currencyAmountLabel = UILabel()
    private let amountLabel = UILabel()

    private let lockImageView = UIImageView()
    private let sentToSelfImageView = UIImageView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let leftWrapperView = UIView()

        leftWrapperView.addSubview(typeIconImageView)
        typeIconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
        }
        typeIconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        typeIconImageView.setContentHuggingPriority(.required, for: .horizontal)

        leftWrapperView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(typeIconImageView.snp.trailing).offset(CGFloat.margin16)
            maker.trailing.lessThanOrEqualToSuperview().inset(CGFloat.margin3x)
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
        }
        dateLabel.font = .body
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)

        leftWrapperView.addSubview(statusView)
        statusView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.trailing.lessThanOrEqualToSuperview().inset(CGFloat.margin3x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        leftWrapperView.addSubview(processingView)
        processingView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.trailing.lessThanOrEqualToSuperview().inset(CGFloat.margin3x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        wrapperView.addSubview(leftWrapperView)
        leftWrapperView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        wrapperView.addSubview(currencyAmountLabel)
        currencyAmountLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(leftWrapperView.snp.trailing).offset(CGFloat.margin3x)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
        }
        currencyAmountLabel.font = .headline1
        currencyAmountLabel.textAlignment = .right

        wrapperView.addSubview(lockImageView)
        lockImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        wrapperView.addSubview(sentToSelfImageView)
        sentToSelfImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        sentToSelfImageView.image = UIImage(named: "arrow_medium_main_down_left_20")?.withRenderingMode(.alwaysTemplate)
        sentToSelfImageView.tintColor = .themeRemus

        wrapperView.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.equalTo(leftWrapperView.snp.trailing).offset(CGFloat.margin3x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
        }
        amountLabel.font = .subhead2
        amountLabel.textAlignment = .right
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: TransactionViewItem) {
        let status = item.status

        dateLabel.textColor = .themeLeah
        switch item.type {
        case .incoming:
            currencyAmountLabel.textColor = .themeGreenD
            typeIconImageView.image = UIImage(named: "arrow_medium_main_down_left_20")?.withRenderingMode(.alwaysTemplate)
            typeIconImageView.tintColor = .themeRemus
        case .outgoing, .sentToSelf:
            currencyAmountLabel.textColor = .themeYellowD
            typeIconImageView.image = UIImage(named: "arrow_medium_main_up_right_20")?.withRenderingMode(.alwaysTemplate)
            typeIconImageView.tintColor = .themeJacob
        case .approve:
            currencyAmountLabel.textColor = .themeLeah
            typeIconImageView.image = UIImage(named: "arrow_swap_approval_2_20")//?.withRenderingMode(.alwaysTemplate)
            typeIconImageView.tintColor = .themeLeah
        }
        amountLabel.textColor = .themeGray

        dateLabel.text = DateHelper.instance.formatTransactionDate(from: item.date).uppercased()
        amountLabel.text = ValueFormatter.instance.format(coinValue: item.coinValue, fractionPolicy: .threshold(high: 0.01, low: 0))

        if let value = item.currencyValue?.nonZero, let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.01)) {
            currencyAmountLabel.text = formattedValue
        } else {
            currencyAmountLabel.text = " "
        }

        if let lockState = item.lockState {
            lockImageView.image = UIImage(named: lockState.locked ? "lock_20" : "unlock_20")
            lockImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(currencyAmountLabel.snp.trailing).offset(CGFloat.margin1x)
                maker.centerY.equalTo(currencyAmountLabel)
            }
        } else {
            lockImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(currencyAmountLabel.snp.trailing)
                maker.centerY.equalTo(currencyAmountLabel)
                maker.size.equalTo(0)
            }
        }

        if item.type == .sentToSelf {
            sentToSelfImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(lockImageView.snp.trailing).offset(CGFloat.margin4)
                maker.centerY.equalTo(currencyAmountLabel)
                maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            }
        } else {
            sentToSelfImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(lockImageView.snp.trailing)
                maker.centerY.equalTo(currencyAmountLabel)
                maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
                maker.size.equalTo(0)
            }
        }

        switch status {
        case .failed:
            statusView.bind(image: UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate), imageTintColor: .themeLucian, status: "transactions.failed".localized)
            statusView.isHidden = false

            processingView.stopAnimating()
            processingView.isHidden = true

        case .pending:
            processingView.bind(type: item.type, progress: 0, hideDoubleSpendImage: item.conflictingTxHash == nil)
            processingView.startAnimating()
            processingView.isHidden = false

            statusView.isHidden = true

        case .processing(let progress):
            processingView.bind(type: item.type, progress: progress, hideDoubleSpendImage: item.conflictingTxHash == nil)
            processingView.startAnimating()
            processingView.isHidden = false

            statusView.isHidden = true

        case .completed:
            statusView.bind(image: UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate), imageTintColor: .themeGray, status: DateHelper.instance.formatTransactionTime(from: item.date))
            statusView.isHidden = false

            processingView.stopAnimating()
            processingView.isHidden = true
        }
    }

}
