import ActionSheet

class AlertTitleItem: BaseActionItem {
    let title: String
    var icon: UIImage?
    var iconTintColor: UIColor?
    let onClose: () -> ()

    init(title: String, icon: UIImage?, iconTintColor: UIColor?, tag: Int, onClose: @escaping () -> ()) {
        self.title = title
        self.icon = icon
        self.iconTintColor = iconTintColor
        self.onClose = onClose

        super.init(cellType: AlertTitleItemView.self, tag: tag, required: true)

        height = AppTheme.alertTitleHeight
    }

}
