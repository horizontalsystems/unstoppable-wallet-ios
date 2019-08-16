import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class MessageItemView: BaseActionItemView {

    var messageLabel = UILabel()

    override var item: MessageItem? { return _item as? MessageItem }

    override func initView() {
        super.initView()
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(AppTheme.alertTextMargin)
            maker.trailing.equalToSuperview().offset(-AppTheme.alertTextMargin)
            maker.top.equalToSuperview().offset(AppTheme.alertBigMargin)
        }
        messageLabel.font = item?.font ?? AppTheme.alertMessageFont
        messageLabel.textColor = item?.color ?? AppTheme.alertMessageDefaultColor
        messageLabel.numberOfLines = 0
        messageLabel.text = item?.text
        messageLabel.textAlignment = .center
    }

    override func updateView() {
        super.updateView()
    }

}
