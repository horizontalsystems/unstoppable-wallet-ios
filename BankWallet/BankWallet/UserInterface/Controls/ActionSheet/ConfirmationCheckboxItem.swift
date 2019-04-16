import UIKit
import ActionSheet

class ConfirmationCheckboxItem: BaseActionItem {

    var checked = false

    var descriptionText: NSAttributedString

    init(descriptionText: NSAttributedString, tag: Int, action: @escaping ((BaseActionItemView) -> ())) {
        self.descriptionText = descriptionText

        super.init(cellType: ConfirmationCheckboxView.self, tag: tag, required: true, action: action)

        showSeparator = false
        height = ConfirmationCheckboxItem.height(for: descriptionText)
    }

    class func height(for string: NSAttributedString) -> CGFloat {
        let textHeight: CGFloat = string.boundingRect(with: CGSize(width: UIScreen.main.bounds.width - 2 * ConfirmationTheme.bigMargin - ConfirmationTheme.smallMargin - ConfirmationTheme.checkboxSize - ActionSheetTheme.sideMargin * 2, height: .greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size.height
        return ceil(max(textHeight, ConfirmationTheme.checkboxSize) + ConfirmationTheme.bigMargin)
    }

}
