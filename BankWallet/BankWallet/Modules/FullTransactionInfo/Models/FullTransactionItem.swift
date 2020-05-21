import UIKit

enum ShowExtra { case none, icon, token, hash }

struct FullTransactionItem {
    let icon: String?
    let title: String
    let value: String?

    let clickable: Bool

    init(icon: String? = nil, title: String, value: String?, clickable: Bool = false) {
        self.icon = icon
        self.title = title
        self.value = value
        self.clickable = clickable
    }

}
