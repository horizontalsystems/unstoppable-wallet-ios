import UIKit
import GrouviActionSheet

class BackupCheckboxItem: BaseActionItem {

    var checked = false
    var onCheck: ((Bool) -> ())?

    var descriptionText: NSAttributedString

    init(descriptionText: NSAttributedString, tag: Int? = nil, hidden: Bool = false, required: Bool = false, action: @escaping ((BaseActionItemView) -> ())) {
        self.descriptionText = descriptionText

        super.init(cellType: BackupCheckboxView.self, tag: tag, hidden: hidden, required: required, action: action)
    }

    class func height(for string: NSAttributedString) -> CGFloat {
        let textHeight: CGFloat = string.boundingRect(with: CGSize(width: UIScreen.main.bounds.width - 2 * BackupConfirmationTheme.bigMargin - BackupConfirmationTheme.smallMargin - BackupConfirmationTheme.checkboxSize - ActionSheetTheme.sideMargin * 2, height: .greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size.height
        return ceil(max(textHeight, BackupConfirmationTheme.checkboxSize) + BackupConfirmationTheme.bigMargin)
    }

}
