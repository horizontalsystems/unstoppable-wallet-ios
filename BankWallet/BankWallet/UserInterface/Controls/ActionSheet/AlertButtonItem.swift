import UIKit
import ActionSheet

class AlertButtonItem: BaseButtonItem {
    private static let defaultInsets = UIEdgeInsets(top: ConfirmationTheme.buttonTopMargin, left: ConfirmationTheme.smallMargin, bottom: ConfirmationTheme.smallMargin, right: ConfirmationTheme.smallMargin)

    private let _backgroundStyle: RespondButton.Style
    private let _textStyle: RespondButton.Style
    private let _title: String
    private let _insets: UIEdgeInsets

    override var backgroundStyle: RespondButton.Style { return _backgroundStyle }
    override var textStyle: RespondButton.Style { return _textStyle }
    override var title: String { return _title }
    override var insets: UIEdgeInsets { return _insets }

    init(tag: Int, title: String, textStyle: RespondButton.Style, backgroundStyle: RespondButton.Style, insets: UIEdgeInsets = AlertButtonItem.defaultInsets, onTap: @escaping (() -> ())) {
        _backgroundStyle = backgroundStyle
        _textStyle = textStyle
        _title = title
        _insets = insets

        super.init(cellType: AlertButtonItemView.self, tag: tag, required: true)

        self.onTap = onTap
        isActive = false
        height = _insets.top + ConfirmationTheme.buttonHeight + _insets.bottom
        showSeparator = false
    }

}
