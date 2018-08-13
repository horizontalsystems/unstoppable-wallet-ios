import Foundation
import GrouviActionSheet

class TransactionInfoBaseHashValueItem: BaseActionItem {

    var title: String?
    var value: String?

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, action: ((BaseActionItemView) -> ())? = nil) {
        super.init(cellType: TransactionInfoBaseHashValueItemView.self, tag: tag, hidden: hidden, required: required, action: action)
        height = TransactionInfoTheme.itemHeight
    }

}
