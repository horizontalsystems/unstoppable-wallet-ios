import UIKit
import UIExtensions
import SnapKit

class FullTransactionHeaderCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let titleHolder = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.preservesSuperviewLayoutMargins = true

        contentView.addSubview(titleHolder)
        titleHolder.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.trailing.equalTo(contentView.snp.trailingMargin)
            maker.bottom.equalToSuperview()
        }

        titleHolder.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leadingMargin.trailingMargin.top.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String? = nil, font: UIFont = .subhead1, color: UIColor = .themeGray) {
        titleLabel.text = title
        titleLabel.font = font
        titleLabel.textColor = color
    }

}
