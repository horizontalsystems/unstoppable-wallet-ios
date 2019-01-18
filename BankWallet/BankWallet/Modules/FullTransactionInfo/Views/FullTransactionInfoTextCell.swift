import UIKit
import SnapKit

class FullTransactionInfoTextCell: UITableViewCell {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionView = TransactionInfoDescriptionView()
    let separatorView = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = FullTransactionInfoTheme.cellBackground
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        titleLabel.font = FullTransactionInfoTheme.font
        titleLabel.textColor = FullTransactionInfoTheme.titleColor
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
        }
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        contentView.addSubview(titleLabel)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.trailing.equalTo(titleLabel.snp.leading).offset(-FullTransactionInfoTheme.iconRightMargin)
            maker.centerY.equalToSuperview()
        }
        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(FullTransactionInfoTheme.margin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(contentView.snp.trailingMargin)
        }

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.height.equalTo(1 / UIScreen.main.scale)
            maker.leading.bottom.trailing.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(item: FullTransactionItem, last: Bool = false, onTap: (() -> ())? = nil) {
        if let icon = item.icon {
            iconImageView.image = UIImage(named: icon)?.tinted(with: TransactionInfoDescriptionTheme.buttonIconColor)
            iconImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(contentView.snp.leadingMargin)
                maker.trailing.equalTo(titleLabel.snp.leading).offset(-FullTransactionInfoTheme.iconRightMargin)
                maker.centerY.equalToSuperview()
            }
        } else {
            iconImageView.snp.remakeConstraints { maker in
                maker.leading.equalTo(contentView.snp.leadingMargin)
                maker.trailing.equalTo(titleLabel.snp.leading)
                maker.width.equalTo(0)
                maker.centerY.equalToSuperview()
            }
        }
        contentView.updateConstraintsIfNeeded()
        titleLabel.text = item.title
        separatorView.set(hidden: last)
        descriptionView.bind(value: item.value, font: FullTransactionInfoTheme.font, color: item.titleColor ?? FullTransactionInfoTheme.descriptionColor, showExtra: item.showExtra, onTap: onTap)
    }

}
