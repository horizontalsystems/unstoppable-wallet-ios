import Foundation
import GrouviActionSheet

class TransactionFromToHashItem: BaseActionItem {

    var title: String?
    var value: String?

    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false, action: ((BaseActionItemView) -> ())? = nil) {
        title = transaction.incoming ? "tx_info.bottom_sheet.from_hash".localized : "tx_info.bottom_sheet.to_hash".localized
        value = (transaction.incoming ? transaction.from : transaction.to) + "5F354D2DFK5J8BS9DK4DF3V4N6S8IF89NV4EU"//stab

        super.init(cellType: TransactionFromToHashItemView.self, tag: tag, hidden: hidden, required: required, action: action)
        height = TransactionInfoTheme.itemHeight
    }

}
