import Foundation
import GrouviActionSheet

class TransactionIDHashItem: TransactionInfoBaseHashValueItem {

    init(transaction: TransactionViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        super.init(tag: tag, hidden: hidden, required: required)
        title = "tx_info.bottom_sheet.id_hash".localized
        value = transaction.transactionHash
    }

}
