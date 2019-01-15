import UIKit
import SnapKit

class FullTransactionInfoTextCell: UITableViewCell {
    var titleLabel = UILabel()
    let descriptionView = TransactionInfoDescriptionView()
    var separatorView = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = FullTransactionInfoTheme.cellBackground
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        titleLabel.font = FullTransactionInfoTheme.font
        titleLabel.textColor = FullTransactionInfoTheme.titleColor
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
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
        titleLabel.text = item.title
        separatorView.set(hidden: last)
        descriptionView.bind(value: item.value, font: FullTransactionInfoTheme.font, color: FullTransactionInfoTheme.descriptionColor, showExtra: item.showExtra, onTap: onTap)
    }

}
