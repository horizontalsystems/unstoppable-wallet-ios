import UIKit
import ActionSheet

class AlertButtonItem: BaseButtonItem {
    private let _backgroundStyle: RespondButton.Style
    private let _textStyle: RespondButton.Style
    private let _title: String

    override var backgroundStyle: RespondButton.Style { return _backgroundStyle }
    override var textStyle: RespondButton.Style { return _textStyle }
    override var title: String { return _title }

    init(tag: Int, title: String, textStyle: RespondButton.Style, backgroundStyle: RespondButton.Style, onTap: @escaping (() -> ())) {
        _backgroundStyle = backgroundStyle
        _textStyle = textStyle
        _title = title

        super.init(cellType: AlertButtonItemView.self, tag: tag, required: true)

        self.onTap = onTap
        isActive = false
        height = ConfirmationTheme.buttonTopMargin + ConfirmationTheme.buttonHeight + ConfirmationTheme.smallMargin
        showSeparator = false
    }

}
