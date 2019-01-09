import UIKit
import GrouviExtensions
import SnapKit

class FullTransactionHeaderView: UITableViewHeaderFooterView {
    let titleLabel = UILabel()
    let titleHolder = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        let backgroundView = UIView()
        backgroundView.backgroundColor = .clear

        self.backgroundView = backgroundView

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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String?, font: UIFont = FullTransactionInfoTheme.sectionTitleFont, color: UIColor = FullTransactionInfoTheme.sectionTitleColor) {
        titleLabel.text = title
        titleLabel.font = font
        titleLabel.textColor = color
    }

}
