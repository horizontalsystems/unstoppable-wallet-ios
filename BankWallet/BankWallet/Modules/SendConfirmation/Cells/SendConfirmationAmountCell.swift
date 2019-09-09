import UIKit
import SnapKit

class SendConfirmationAmountCell: AppCell {

    private let primaryAmountLabel = UILabel()
    private let primaryAmountTitleLabel = UILabel()
    private let secondaryAmountLabel = UILabel()
    private let secondaryAmountTitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = SendTheme.holderBackground
        backgroundColor = .clear
        selectionStyle = .none

        addSubview(primaryAmountLabel)
        addSubview(primaryAmountTitleLabel)
        addSubview(secondaryAmountLabel)
        addSubview(secondaryAmountTitleLabel)

        primaryAmountLabel.font = SendTheme.confirmationPrimaryAmountFont
        primaryAmountLabel.textColor = SendTheme.confirmationPrimaryAmountColor
        primaryAmountLabel.textAlignment = .right
        primaryAmountLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.confirmationAmountVerticalMargin)
            maker.leading.equalTo(secondaryAmountTitleLabel.snp.trailing).offset(SendTheme.margin)
        }
        primaryAmountTitleLabel.font = SendTheme.confirmationBottomAmountFont
        primaryAmountTitleLabel.textColor = SendTheme.confirmationBottomAmountColor
        primaryAmountTitleLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.bottom.equalToSuperview().offset(-SendTheme.confirmationAmountVerticalMargin)
        }
        primaryAmountTitleLabel.textAlignment = .right
        secondaryAmountTitleLabel.font = SendTheme.confirmationSecondaryAmountTitleFont
        secondaryAmountTitleLabel.textColor = SendTheme.confirmationSecondaryAmountTitleColor
        secondaryAmountTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(SendTheme.confirmationAmountVerticalMargin)
            maker.leading.equalToSuperview().offset(SendTheme.margin)
        }
        secondaryAmountLabel.font = SendTheme.confirmationBottomAmountFont
        secondaryAmountLabel.textColor = SendTheme.confirmationBottomAmountColor
        secondaryAmountLabel.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().offset(-SendTheme.confirmationAmountVerticalMargin)
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.trailing.equalTo(primaryAmountTitleLabel.snp.leading).offset(SendTheme.margin)
        }

        primaryAmountTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        secondaryAmountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        secondaryAmountTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        primaryAmountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(primaryTitle: String?, primaryAmount: String?, secondaryTitle: String?, secondaryAmount: String?) {
        super.bind(showDisclosure: false, last: false)

        if let primaryAmount = primaryAmount {
            primaryAmountLabel.text = primaryAmount
            primaryAmountTitleLabel.text = primaryTitle
        } else {
            primaryAmountLabel.text = nil
            primaryAmountTitleLabel.text = nil
        }
        if let secondaryAmount = secondaryAmount {
            secondaryAmountLabel.text = secondaryAmount
            secondaryAmountTitleLabel.text = secondaryTitle
        } else {
            secondaryAmountLabel.text = nil
            secondaryAmountTitleLabel.text = nil
        }
    }

}
