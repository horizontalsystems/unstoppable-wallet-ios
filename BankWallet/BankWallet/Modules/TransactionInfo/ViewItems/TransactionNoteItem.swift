import ActionSheet
import UIKit

class TransactionNoteItem: BaseActionItem {
    let note: String
    let imageName: String

    let iconName: String?
    let onTap: (() -> ())?

    init(note: String, imageName: String, tag: Int? = nil, iconName: String? = nil, onTap: (() -> ())? = nil) {
        self.note = note
        self.imageName = imageName
        self.iconName = iconName
        self.onTap = onTap

        super.init(cellType: TransactionNoteItemView.self, tag: tag, required: true)

        height = TransactionNoteItemView.noteHeight(note: note, showRightButton: iconName != nil) + 2 * CGFloat.margin4x
    }

}
