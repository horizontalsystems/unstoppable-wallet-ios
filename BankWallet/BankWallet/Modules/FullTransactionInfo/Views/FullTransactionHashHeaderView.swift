import UIKit
import UIExtensions
import SnapKit

class FullTransactionHashHeaderView: UITableViewHeaderFooterView {
    private let descriptionView = HashView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.backgroundView = UIView()

        contentView.preservesSuperviewLayoutMargins = true

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.trailing.equalTo(contentView.snp.trailingMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(value: String?, color: UIColor = .themeGray, onTap: (() -> ())?) {
        descriptionView.bind(value: value, showExtra: .hash, onTap: onTap)
    }

}
