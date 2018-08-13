import Foundation
import GrouviActionSheet

class TransactionFromHashItem: TransactionInfoBaseHashValueItem {

    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false, action: ((BaseActionItemView) -> ())? = nil) {
        super.init(tag: tag, hidden: hidden, required: required, action: action)
        title = "tx_info.bottom_sheet.from_hash".localized
        value = transaction.from + "5F354D2DFK5J8BS9DK4DF3V4N6S8IF89NV4EU"//stab
    }

}
