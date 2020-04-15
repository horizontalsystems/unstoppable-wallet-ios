import ActionSheet

class AlertTextItem: BaseActionItem {
    let text: String
    let important: Bool

    init(text: String, important: Bool, last: Bool, tag: Int) {
        self.text = text
        self.important = important

        super.init(cellType: AlertTextItemView.self, tag: tag, required: true)

        showSeparator = !last

        if important {
            let textHeight = HighlightedDescriptionView.height(containerWidth: UIScreen.main.bounds.width - 2 * CGFloat.margin4x - 2 * ActionSheetTheme.sideMargin, text: text)
            height = textHeight + CGFloat.margin4x + (!last ? CGFloat.margin4x : 0)
        } else {
            let textHeight = text.height(forContainerWidth: UIScreen.main.bounds.width - 2 * CGFloat.margin4x - 2 * ActionSheetTheme.sideMargin, font: .subhead1)
            height = textHeight + CGFloat.margin4x + CGFloat.margin2x
        }
    }

}
