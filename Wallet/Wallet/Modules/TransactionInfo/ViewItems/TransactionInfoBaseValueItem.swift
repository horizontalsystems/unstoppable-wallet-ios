import Foundation
import GrouviActionSheet

class TransactionInfoBaseValueItem: BaseActionItem {

    var title: String?
    var value: String?
    var valueImage: UIImage?
    var valueColor: UIColor?

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        super.init(cellType: TransactionInfoBaseValueItemView.self, tag: tag, hidden: hidden, required: required)
        height = TransactionInfoTheme.itemHeight
    }

}
