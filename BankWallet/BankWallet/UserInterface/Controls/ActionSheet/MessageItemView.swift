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
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(AppTheme.alertBigMargin)
        }
        messageLabel.font = item?.font ?? .subhead1
        messageLabel.textColor = item?.color ?? .themeOz
        messageLabel.numberOfLines = 0
        messageLabel.text = item?.text
        messageLabel.textAlignment = .center
    }

    override func updateView() {
        super.updateView()
    }

}
