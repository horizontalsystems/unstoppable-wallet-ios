import ActionSheet

class AlertTitleItem: BaseActionItem {
    let title: String
    var subtitle: String?
    var icon: UIImage?
    var iconTintColor: UIColor?
    var onClose: (() -> ())?

    var bindSubtitle: ((String?) -> ())?

    init(title: String, subtitle: String? = nil, icon: UIImage? = nil, iconTintColor: UIColor? = nil, tag: Int, onClose: (() -> ())? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconTintColor = iconTintColor
        self.onClose = onClose

        super.init(cellType: AlertTitleItemView.self, tag: tag, required: true)

        height = 62
    }

}
