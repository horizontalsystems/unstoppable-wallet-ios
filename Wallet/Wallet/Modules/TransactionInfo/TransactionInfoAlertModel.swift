import UIKit
import GrouviActionSheet

class TransactionInfoAlertModel: BaseAlertModel {

    init(transaction: TransactionRecordViewItem, onCopyFromAddress: (() -> ())? = nil) {
        let titleItem = TransactionTitleItem(transaction: transaction, tag: 0, required: true)

        super.init()

        addItemView(titleItem)

        let statusItem = TransactionStatusItem(transaction: transaction, tag: 1, required: true)
        addItemView(statusItem)

        let fromHashItem = TransactionFromHashItem(transaction: transaction, tag: 2, required: true) { [weak self] _ in
            onCopyFromAddress?()
        }

        addItemView(fromHashItem)

        let amountItem = TransactionAmountItem(transaction: transaction, tag: 3, required: true)
        addItemView(amountItem)

        let idHashItem = TransactionIDHashItem(transaction: transaction, tag: 4, required: true)
        idHashItem.showSeparator = false
        addItemView(idHashItem)

        let closeItem = TransactionCloseItem(tag: 5, required: true, onTap: { [weak self] in
            self?.dismiss?(true)
        })
        addItemView(closeItem)
    }

}
