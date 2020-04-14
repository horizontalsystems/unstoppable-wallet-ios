import ActionSheet

class RadioItem: BaseActionItem {
    let title: String
    var subtitle: String
    var selected: Bool

    init(title: String, subtitle: String, selected: Bool, tag: Int, action: @escaping ((BaseActionItemView) -> ())) {
        self.title = title
        self.subtitle = subtitle
        self.selected = selected

        super.init(cellType: RadioItemView.self, tag: tag, required: true, action: action)

        height = 60
    }

}
