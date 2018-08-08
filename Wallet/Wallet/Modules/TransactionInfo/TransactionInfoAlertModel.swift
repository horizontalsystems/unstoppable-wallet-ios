import UIKit
import GrouviActionSheet

class TransactionInfoAlertModel: BaseAlertModel {

    init(transaction: TransactionRecordViewItem) {
        let titleItem = TransactionTitleItem(transaction: transaction)

        super.init()

        addItemView(titleItem)
    }

}
