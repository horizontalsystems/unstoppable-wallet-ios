import ActionSheet

class AlertTitleItem: BaseActionItem {
    let title: String
    var subtitle: String?
    var icon: UIImage?
    var iconTintColor: UIColor?
    var onClose: (() -> ())?

    var bindSubtitle: ((String?) -> ())?

    init(title: String, subtitle: String?, icon: UIImage?, iconTintColor: UIColor?, tag: Int, onClose: (() -> ())?) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconTintColor = iconTintColor
        self.onClose = onClose

        super.init(cellType: AlertTitleItemView.self, tag: tag, required: true)

        height = AppTheme.alertTitleHeight
    }

}
