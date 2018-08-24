import Foundation
import GrouviActionSheet

class TransactionFromToHashItem: BaseActionItem {

    var title: String?
    var value: String?
    var onHashTap: (() -> ())?

    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false, onHashTap: (() -> ())? = nil, action: ((BaseActionItemView) -> ())? = nil) {
        title = transaction.incoming ? "tx_info.bottom_sheet.from_hash".localized : "tx_info.bottom_sheet.to_hash".localized
        value = (transaction.incoming ? transaction.from : transaction.to)
        self.onHashTap = onHashTap

        super.init(cellType: TransactionFromToHashItemView.self, tag: tag, hidden: hidden, required: required, action: action)
        height = TransactionInfoTheme.itemHeight
    }

}
