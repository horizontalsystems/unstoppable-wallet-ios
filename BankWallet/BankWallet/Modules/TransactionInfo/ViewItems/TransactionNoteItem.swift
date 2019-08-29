import ActionSheet
import UIKit

class TransactionNoteItem: BaseActionItem {
    let note: String

    init(note: String, tag: Int? = nil) {
        self.note = note

        super.init(cellType: TransactionNoteItemView.self, tag: tag, required: true)

        let textHeight = note.height(forContainerWidth: UIScreen.main.bounds.width - 2 * TransactionInfoTheme.regularMargin - 2 * ActionSheetTheme.sideMargin, font: TransactionInfoTheme.itemNoteFont)
        height = textHeight + 2 * TransactionInfoTheme.regularMargin
    }

}
