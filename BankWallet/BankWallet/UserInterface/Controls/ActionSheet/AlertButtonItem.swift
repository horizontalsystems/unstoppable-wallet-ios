import UIKit
import ActionSheet

class AlertButtonItem: BaseButtonItem {
    private static let defaultInsets = UIEdgeInsets(top: ConfirmationTheme.buttonTopMargin, left: ConfirmationTheme.smallMargin, bottom: ConfirmationTheme.smallMargin, right: ConfirmationTheme.smallMargin)

    private let _createButton: (() -> (UIButton))
    private let _title: String
    private let _insets: UIEdgeInsets

    override var insets: UIEdgeInsets { _insets }
    override var createButton: UIButton { _createButton() }
    override var title: String { _title }

    init(tag: Int, title: String, createButton: @escaping (() -> (UIButton)), insets: UIEdgeInsets = AlertButtonItem.defaultInsets, onTap: @escaping (() -> ())) {
        self._createButton = createButton
        _title = title
        _insets = insets

        super.init(cellType: AlertButtonItemView.self, tag: tag, required: true)

        self.onTap = onTap
        isEnabled = false
        height = _insets.top + ConfirmationTheme.buttonHeight + _insets.bottom
        showSeparator = false
    }

}
