import ActionSheet

class TransactionNoteItem: BaseActionItem {
    let note: String

    init(note: String, tag: Int? = nil) {
        self.note = note

        super.init(cellType: TransactionNoteItemView.self, tag: tag, required: true)

        height = TransactionInfoTheme.itemNoteHeight
    }

}
