import UIKit
import ActionSheet

class AlertButtonItem: BaseButtonItem {
    private static let defaultInsets = UIEdgeInsets(top: CGFloat.margin8x, left: CGFloat.margin4x, bottom: CGFloat.margin4x, right: CGFloat.margin4x)

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
        height = _insets.top + CGFloat.heightButton + _insets.bottom
        showSeparator = false
    }

}
