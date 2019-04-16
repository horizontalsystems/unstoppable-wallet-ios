import UIKit
import ActionSheet

class BaseButtonItem: BaseActionItem {
    var backgroundStyle: RespondButton.Style { fatalError("not implemented") }
    var textStyle: RespondButton.Style { fatalError("not implemented") }
    var title: String { fatalError("not implemented") }
    var isActive = true
    var onTap: (() -> ())?
}
