import UIKit
import ActionSheet

class MessageItem: BaseActionItem  {
    var text: String
    var font: UIFont
    var color: UIColor

    init(text: String, font: UIFont, color: UIColor) {
        self.text = text
        self.font = font
        self.color = color

        super.init(cellType: MessageItemView.self, tag: nil, required: true)

        showSeparator = true
        height = MessageItem.height(for: text)
    }

    class func height(for string: String) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.subhead1
        ]
        let string = NSAttributedString(string: string, attributes: attributes)
        let textHeight: CGFloat = string.boundingRect(with: CGSize(width: UIScreen.main.bounds.width - 2 * AlertViewController.sideMargin - 2 * CGFloat.margin4x, height: .greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size.height
        return ceil(textHeight + MessageItemView.bigMargin + MessageItemView.bigMargin)
    }

}
