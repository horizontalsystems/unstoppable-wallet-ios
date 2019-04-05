import UIKit
import GrouviExtensions
import SnapKit

class FullTransactionHeaderCell: UITableViewCell {
    let titleLabel = UILabel()
    let titleHolder = UIView()
    let topSeparatorView = UIView()
    let bottomSeparatorView = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.preservesSuperviewLayoutMargins = true

        contentView.addSubview(titleHolder)
        titleHolder.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(FullTransactionInfoTheme.sectionTitleTopMargin)
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.trailing.equalTo(contentView.snp.trailingMargin)
            maker.bottom.equalToSuperview()
        }
        titleHolder.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leadingMargin.trailingMargin.top.equalToSuperview()
        }

        topSeparatorView.backgroundColor = AppTheme.darkSeparatorColor
        contentView.addSubview(topSeparatorView)
        topSeparatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
        bottomSeparatorView.backgroundColor = SettingsTheme.separatorColor
        addSubview(bottomSeparatorView)
        bottomSeparatorView.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String? = nil, font: UIFont = FullTransactionInfoTheme.sectionTitleFont, color: UIColor = FullTransactionInfoTheme.sectionTitleColor, showTopSeparator: Bool = true, showBottomSeparator: Bool = true) {
        titleLabel.text = title
        titleLabel.font = font
        titleLabel.textColor = color
        topSeparatorView.isHidden = !showTopSeparator
        bottomSeparatorView.isHidden = !showBottomSeparator
    }

}
