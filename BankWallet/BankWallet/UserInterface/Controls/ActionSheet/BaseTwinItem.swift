import UIKit
import ActionSheet

class BaseTwinItem: BaseActionItem {

    enum ChangeStyle: Int { case fromLeft, fromRight, alpha }

    var firstItem: BaseActionItem
    var secondItem: BaseActionItem
    var showFirstItem = true

    var changeStyle: ChangeStyle = .fromLeft

    var updateItems: ((Bool) -> ())? // true for right

    init(cellType: BaseActionItemView.Type = BaseTwinItemView.self, first firstItem: BaseActionItem, second secondItem: BaseActionItem, height: CGFloat = 44, tag: Int? = nil, hidden: Bool = false, required: Bool = false, action: ((BaseActionItemView) -> ())? = nil) {
        self.firstItem = firstItem
        self.secondItem = secondItem

        super.init(cellType: cellType, tag: tag, hidden: hidden, required: required, action: action)

        self.height = height
//        nibType = true
    }

}