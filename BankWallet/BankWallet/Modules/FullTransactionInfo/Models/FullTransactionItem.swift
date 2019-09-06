import UIKit

enum ShowExtra { case none, icon, token, hash }

struct FullTransactionItem {
    let icon: String?
    let title: String
    let titleColor: UIColor?
    let value: String?

    let clickable: Bool
    let url: String?

    let showExtra: ShowExtra

    init(icon: String? = nil, title: String, titleColor: UIColor? = nil, value: String?, clickable: Bool = false, url: String? = nil, showExtra: ShowExtra = .none) {
        self.icon = icon
        self.title = title
        self.titleColor = titleColor
        self.value = value
        self.clickable = clickable
        self.url = url
        self.showExtra = showExtra
    }

}
