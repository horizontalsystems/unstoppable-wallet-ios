import UIKit
import SnapKit

class TransactionCell: UITableViewCell {

    var dateLabel = UILabel()
    var statusLabel = UILabel()
    var amountLabel = UILabel()
    var infoButton = UIButton()
    var infoImageView = UIImageView(image: UIImage(named: "Info Icon")?.withRenderingMode(.alwaysTemplate))

    var separatorView = UIView()

    var onInfo: (() -> ())?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        dateLabel.font = TransactionsTheme.dateLabelFont
        dateLabel.textColor = TransactionsTheme.dateLabelTextColor
        statusLabel.font = TransactionsTheme.statusLabelFont
        statusLabel.textColor = TransactionsTheme.statusLabelTextColor
        amountLabel.font = TransactionsTheme.amountLabelFont
        separatorView.backgroundColor = TransactionsTheme.separatorColor

        infoImageView.tintColor = TransactionsTheme.infoIconTintColor

        infoButton.addTarget(self, action: #selector(onInfo(sender:)), for: .touchUpInside)

        contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(TransactionsTheme.cellBigMargin)
            maker.leading.equalToSuperview().offset(self.layoutMargins.left * 2)
        }
        contentView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.dateLabel.snp.bottom).offset(TransactionsTheme.cellSmallMargin)
            maker.leading.equalToSuperview().offset(self.layoutMargins.left * 2)
        }

        contentView.addSubview(infoImageView)
        contentView.addSubview(infoButton)
        contentView.addSubview(amountLabel)
        infoButton.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.leading.equalTo(self.amountLabel.snp.trailing)
        }
        infoImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(self.layoutMargins.right * 2)
            maker.size.equalTo(self.infoImageView.image?.size ?? CGSize.zero)
        }
        amountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        amountLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(self.infoImageView.snp.leading).inset(-self.layoutMargins.right * 2)
            maker.leading.equalTo(self.dateLabel.snp.trailing).offset(TransactionsTheme.cellSmallMargin)
        }

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: TransactionRecordViewItem, onInfo: @escaping (() -> ())) {
        self.onInfo = onInfo

        amountLabel.textColor = item.incoming ? TransactionsTheme.incomingTextColor : TransactionsTheme.outgoingTextColor

        dateLabel.text = DateHelper.instance.formatTransactionTime(from: item.date)
        statusLabel.text = "transactions.\(item.status.rawValue)".localized
        amountLabel.text = (item.incoming ? "+ " : "- ") + item.amount.formattedAmount
    }

    @objc private func onInfo(sender: UIButton) {
        onInfo?()
    }

}
