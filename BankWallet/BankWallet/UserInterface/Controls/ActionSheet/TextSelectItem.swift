import UIKit
import ActionSheet

class TextSelectItem: BaseActionItem {

    var text: String
    var font: UIFont
    var color: UIColor
    var selected: Bool

    init(text: String, font: UIFont, color: UIColor, height: CGFloat, selected: Bool = false, tag: Int, action: ((BaseActionItemView) -> ())? = nil) {
        self.text = text
        self.font = font
        self.color = color
        self.selected = selected

        super.init(cellType: TextSelectItemView.self, tag: tag, required: true, action: action)

        showSeparator = true
        self.height = height
    }

}
