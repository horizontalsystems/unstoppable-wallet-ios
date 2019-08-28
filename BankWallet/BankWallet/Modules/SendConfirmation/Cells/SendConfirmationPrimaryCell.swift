import UIKit

class SendConfirmationPrimaryCell: UITableViewCell {

    private let holderView = UIView()

    private let primaryAmountLabel = UILabel()
    private let secondaryAmountLabel = UILabel()
    private let lineView = UIView()
    private let toLabel = UILabel()
    private let hashView = HashView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none

        addSubview(holderView)

        holderView.addSubview(primaryAmountLabel)
        holderView.addSubview(secondaryAmountLabel)
        holderView.addSubview(lineView)
        holderView.addSubview(hashView)
        holderView.addSubview(toLabel)

        holderView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(SendTheme.margin)
            maker.top.bottom.equalToSuperview()
        }

        holderView.layer.cornerRadius = SendTheme.holderCornerRadius

        holderView.layer.borderWidth = SendTheme.holderBorderWidth
        holderView.layer.borderColor = SendTheme.holderBorderColor.cgColor
        holderView.backgroundColor = SendTheme.holderBackground

        primaryAmountLabel.font = SendTheme.confirmationPrimaryAmountFont
        primaryAmountLabel.textColor = SendTheme.confirmationPrimaryAmountColor
        primaryAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(SendTheme.confirmationPrimaryMargin)
        }

        secondaryAmountLabel.font = SendTheme.confirmationSecondaryFont
        secondaryAmountLabel.textColor = SendTheme.confirmationSecondaryColor
        secondaryAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.primaryAmountLabel.snp.bottom).offset(SendTheme.confirmationSecondaryTopMargin)
        }

        lineView.backgroundColor = SendTheme.amountLineColor
        lineView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview().offset(SendTheme.confirmationPrimaryLineTopMargin)
            maker.height.equalTo(SendTheme.amountLineHeight)
        }

        toLabel.font = SendTheme.confirmationToLabelFont
        toLabel.textColor = SendTheme.confirmationToLabelColor
        toLabel.text = "send.confirmation.to".localized
        toLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalTo(lineView.snp.bottom).offset(SendTheme.confirmationToLabelTopMargin)
        }
        toLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        toLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        hashView.snp.makeConstraints { maker in
            maker.leading.equalTo(toLabel.snp.trailing).offset(SendTheme.smallMargin)
            maker.top.equalTo(lineView.snp.bottom).offset(SendTheme.confirmationReceiverTopMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
        }
        hashView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        hashView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(primaryAmount: String?, secondaryAmount: String?, receiver: String, onHashTap: (() -> ())?) {
        primaryAmountLabel.text = primaryAmount
        secondaryAmountLabel.text = secondaryAmount
        hashView.bind(value: receiver, showExtra: .icon, onTap: onHashTap)
    }

}
