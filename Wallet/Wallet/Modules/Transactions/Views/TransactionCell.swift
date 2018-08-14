import UIKit
import GrouviExtensions
import SnapKit

class TransactionCell: UITableViewCell {

    var avatarImageView = UIImageView(image: UIImage(named: "Avatar Placeholder"))
    var amountLabel = UILabel()
    var fiatAmountFromLabel = UILabel()
    var dateLabel = UILabel()
    var statusImageView = UIImageView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        amountLabel.font = TransactionsTheme.amountLabelFont
        fiatAmountFromLabel.font = TransactionsTheme.fiatAmountLabelFont
        fiatAmountFromLabel.textColor = TransactionsTheme.fiatAmountLabelColor
        dateLabel.font = TransactionsTheme.dateLabelFont
        dateLabel.textColor = TransactionsTheme.dateLabelTextColor

        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(self.layoutMargins.left * 2)
            maker.size.equalTo(TransactionsTheme.avatarSize)
        }
        contentView.addSubview(amountLabel)
        amountLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        amountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        amountLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(TransactionsTheme.topMargin)
            maker.leading.equalTo(self.avatarImageView.snp.trailing).offset(TransactionsTheme.cellMediumMargin)
        }
        contentView.addSubview(fiatAmountFromLabel)
        fiatAmountFromLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.avatarImageView.snp.trailing).offset(TransactionsTheme.cellMediumMargin)
            maker.top.equalTo(self.amountLabel.snp.bottom).offset(TransactionsTheme.cellSmallMargin)
        }
        contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.amountLabel.snp.trailing).offset(-TransactionsTheme.cellMediumMargin)
            maker.top.equalToSuperview().offset(TransactionsTheme.cellMediumMargin)
            maker.trailing.equalToSuperview().offset(-self.layoutMargins.left * 2)
        }
        contentView.addSubview(statusImageView)
        statusImageView.snp.makeConstraints { maker in
            maker.size.equalTo(TransactionsTheme.statusImageViewSize)
            maker.top.equalTo(self.dateLabel.snp.bottom).offset(TransactionsTheme.statusTopMargin)
            maker.leading.equalTo(self.fiatAmountFromLabel.snp.trailing).offset(TransactionsTheme.cellMediumMargin)
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
        amountLabel.textColor = item.incoming ? TransactionsTheme.incomingTextColor : TransactionsTheme.outgoingTextColor

        //stab
        let fiatAmount = CurrencyHelper.instance.formattedValue(for: CurrencyValue(currency: DollarCurrency(), value: abs(item.amount.value) * 6000)) ?? ""
        let fromAddress = item.from + "SA2DS3F9F4R7GE0G23SD9F7SD92SE38F4G7"
        let endIndex = fromAddress.index(fromAddress.startIndex, offsetBy: 5)
        let firstChars = fromAddress[fromAddress.startIndex ..< endIndex]
        let fiatFromText = "\(fiatAmount) \(item.incoming ? "transactions.from".localized : "transactions.to".localized) \(firstChars)..."
        fiatAmountFromLabel.text = fiatFromText

        dateLabel.text = DateHelper.instance.formatTransactionTime(from: item.date)
        amountLabel.text = (item.incoming ? "+ " : "- ") + CoinValueHelper.formattedAmount(for: item.amount)

        statusImageView.image = item.status == .pending ? UIImage(named: "Transaction Processing Icon") : UIImage(named: "Transaction Success Icon")
    }

}
