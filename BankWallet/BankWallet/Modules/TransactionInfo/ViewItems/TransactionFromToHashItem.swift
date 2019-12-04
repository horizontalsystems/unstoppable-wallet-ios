import Foundation
import ActionSheet

class TransactionFromToHashItem: BaseActionItem {

    var title: String
    var value: String
    var onHashTap: (() -> ())?

    init(title: String, value: String, tag: Int? = nil, hidden: Bool = false, required: Bool = false, onHashTap: (() -> ())? = nil, action: ((BaseActionItemView) -> ())? = nil) {
        self.title = title
        self.value = value
        self.onHashTap = onHashTap

        super.init(cellType: TransactionFromToHashItemView.self, tag: tag, hidden: hidden, required: required, action: action)

        height = .heightSingleLineCell
    }

}
