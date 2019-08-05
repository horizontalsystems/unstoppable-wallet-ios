import ActionSheet

class AlertTitleItem: BaseActionItem {
    let title: String
    var icon: UIImage?
    var iconTintColor: UIColor?

    init(title: String, icon: UIImage?, iconTintColor: UIColor?, tag: Int) {
        self.title = title
        self.icon = icon
        self.iconTintColor = iconTintColor

        super.init(cellType: AlertTitleItemView.self, tag: tag, required: true)

        height = AppTheme.alertTitleHeight
    }

}
