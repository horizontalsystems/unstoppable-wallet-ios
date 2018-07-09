import UIKit
import SnapKit

class TransactionCell: UITableViewCell {

    var dateLabel = UILabel()
    var statusLabel = UILabel()
    var amountLabel = UILabel()

    let infoButton = RespondView()

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

        let infoImageView = TintImageView(image: UIImage(named: "Info Icon"), tintColor: TransactionsTheme.infoIconTintColor, selectedTintColor: TransactionsTheme.infoIconHighlightedTintColor)
        infoButton.delegate = infoImageView

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

        infoButton.addSubview(infoImageView)
        contentView.addSubview(infoButton)
        contentView.addSubview(amountLabel)
        infoButton.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.leading.equalTo(self.amountLabel.snp.trailing)
            maker.width.equalTo(TransactionsTheme.cellSmallMargin + (infoImageView.image?.size.width ?? 0) + self.layoutMargins.left * 2)
        }
        infoImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().inset(TransactionsTheme.cellSmallMargin)
            maker.size.equalTo(infoImageView.image?.size ?? CGSize.zero)
        }
        amountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        amountLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(self.dateLabel.snp.trailing).offset(TransactionsTheme.cellSmallMargin)
            maker.trailing.equalTo(infoButton.snp.leading)
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

    func bind(item: TransactionRecordViewItem, onInfo: @escaping (() -> ())) {
        infoButton.handleTouch = onInfo

        amountLabel.textColor = item.incoming ? TransactionsTheme.incomingTextColor : TransactionsTheme.outgoingTextColor

        dateLabel.text = DateHelper.instance.formatTransactionTime(from: item.date)
        statusLabel.text = "transactions.\(item.status.rawValue)".localized
        amountLabel.text = (item.incoming ? "+ " : "- ") + item.amount.formattedAmount
    }

}
