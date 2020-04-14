import ActionSheet

class AlertTextItem: BaseActionItem {
    let text: String

    init(text: String, tag: Int) {
        self.text = text

        super.init(cellType: AlertTextItemView.self, tag: tag, required: true)

        let textHeight = HighlightedDescriptionView.height(containerWidth: UIScreen.main.bounds.width - 2 * CGFloat.margin4x - 2 * ActionSheetTheme.sideMargin, text: text)
        height = textHeight + 2 * CGFloat.margin3x
    }

}
