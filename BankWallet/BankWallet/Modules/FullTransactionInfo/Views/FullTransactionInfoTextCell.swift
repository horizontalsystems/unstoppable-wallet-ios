import UIKit
import SnapKit

class FullTransactionInfoTextCell: SettingsCell {
    private let descriptionView = HashView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = FullTransactionInfoTheme.cellBackground
        contentView.backgroundColor = .clear

        titleLabel.font = FullTransactionInfoTheme.font
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        iconImageView.tintColor = TransactionInfoDescriptionTheme.buttonIconColor
        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(FullTransactionInfoTheme.margin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(self.disclosureImageView.snp.leading).offset(-SettingsTheme.cellBigMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(item: FullTransactionItem, selectionStyle: SelectionStyle = .none, showDisclosure: Bool = false, last: Bool = false, onTap: (() -> ())? = nil) {
        super.bind(titleIcon: item.icon.flatMap { UIImage(named: $0) }, title: item.title, titleColor: FullTransactionInfoTheme.titleColor, showDisclosure: showDisclosure, last: last)
        self.selectionStyle = selectionStyle

        descriptionView.snp.remakeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(FullTransactionInfoTheme.margin)
            maker.centerY.equalToSuperview()

            let descriptionBackgroundOffset = onTap == nil ? TransactionInfoDescriptionTheme.horizontalMargin : 0
            if showDisclosure {
                maker.trailing.equalTo(self.disclosureImageView.snp.leading).offset(-FullTransactionInfoTheme.disclosureLeftMargin + descriptionBackgroundOffset)
            } else {
                maker.trailing.equalTo(contentView.snp.trailingMargin).offset(descriptionBackgroundOffset)
            }
        }

        descriptionView.bind(value: item.value, color: item.titleColor ?? FullTransactionInfoTheme.descriptionColor, showExtra: item.showExtra, onTap: onTap)
        descriptionView.isUserInteractionEnabled = onTap != nil
    }

}
