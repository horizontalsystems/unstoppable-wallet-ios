import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionFromToHashItemView: BaseActionItemView {

    var titleLabel = UILabel()
    let hashView = HashView()

    override var item: TransactionFromToHashItem? { return _item as? TransactionFromToHashItem
    }

    override func initView() {
        super.initView()

        backgroundColor = .themeLawrence

        addSubview(titleLabel)
        addSubview(hashView)

        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.font = .subhead2
        titleLabel.textColor = .themeGray

        hashView.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(CGFloat.margin12x)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
    }

    override func updateView() {
        super.updateView()
        titleLabel.text = item?.title
        hashView.bind(value: item?.value, showExtra: .icon, onTap: item?.onHashTap)
    }

}
