import UIKit
import ActionSheet
import SnapKit

class AlertTextItemView: BaseActionItemView {
    private let textLabel = UILabel()

    override var item: AlertTextItem? { return _item as? AlertTextItem }

    override func initView() {
        super.initView()

        addSubview(textLabel)
        textLabel.font = .subhead1
        textLabel.textColor = .themeGray
        textLabel.numberOfLines = 0
        textLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        textLabel.text = item?.text
    }

}
