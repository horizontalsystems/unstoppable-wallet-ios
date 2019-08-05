import UIKit
import ActionSheet
import SnapKit

class AlertTextItemView: BaseActionItemView {
    private let textLabel = UILabel()

    override var item: AlertTextItem? { return _item as? AlertTextItem }

    override func initView() {
        super.initView()

        addSubview(textLabel)
        textLabel.font = AppTheme.alertTextFont
        textLabel.textColor = AppTheme.alertTextColor
        textLabel.numberOfLines = 0
        textLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalToSuperview().offset(AppTheme.alertTextMargin)
            maker.trailing.equalToSuperview().offset(-AppTheme.alertTextMargin)
        }

        textLabel.text = item?.text
    }

}
