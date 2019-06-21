import UIKit
import ActionSheet

class TextSelectItem: BaseActionItem {

    var text: String
    var selected: Bool

    init(text: String, selected: Bool = false, tag: Int, action: @escaping ((BaseActionItemView) -> ())) {
        self.text = text
        self.selected = selected

        super.init(cellType: TextSelectItemView.self, tag: tag, required: true, action: action)

        showSeparator = true
        height = AppTheme.actionSheetTextSelectHeight
    }

}
