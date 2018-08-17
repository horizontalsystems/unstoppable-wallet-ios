import UIKit
import SnapKit

class FullTransactionInfoTextCell: UITableViewCell {
    var titleLabel = UILabel()
    var descriptionLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = FullTransactionInfoTheme.cellBackground
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        titleLabel.font = FullTransactionInfoTheme.font
        titleLabel.textColor = FullTransactionInfoTheme.titleColor
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(self.layoutMargins.left * 2)
            maker.centerY.equalToSuperview()
        }

        contentView.addSubview(descriptionLabel)
        descriptionLabel.lineBreakMode = .byTruncatingMiddle
        descriptionLabel.textAlignment = .right
        descriptionLabel.font = FullTransactionInfoTheme.font
        descriptionLabel.textColor = FullTransactionInfoTheme.descriptionColor
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(FullTransactionInfoTheme.margin)
            maker.trailing.equalToSuperview().offset(-self.layoutMargins.left * 2)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String?, description: String?) {
        titleLabel.text = title
        descriptionLabel.text = description
    }

}
