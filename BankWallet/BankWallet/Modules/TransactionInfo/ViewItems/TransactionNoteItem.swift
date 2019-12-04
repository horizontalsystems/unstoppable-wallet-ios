import ActionSheet
import UIKit

class TransactionNoteItem: BaseActionItem {
    let note: String

    init(note: String, tag: Int? = nil) {
        self.note = note

        super.init(cellType: TransactionNoteItemView.self, tag: tag, required: true)

        let textHeight = note.height(forContainerWidth: UIScreen.main.bounds.width - 2 * CGFloat.margin4x - 2 * ActionSheetTheme.sideMargin, font: .appSubhead2)
        height = textHeight + 2 * CGFloat.margin4x
    }

}
