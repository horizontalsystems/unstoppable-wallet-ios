import UIKit
import ActionSheet

class BaseButtonItem: BaseActionItem {
    var createButton: UIButton { fatalError("not implemented") }
    var title: String { fatalError("not implemented") }
    var insets: UIEdgeInsets { fatalError("not implemented") }
    var isEnabled = true
    var onTap: (() -> ())?
}
