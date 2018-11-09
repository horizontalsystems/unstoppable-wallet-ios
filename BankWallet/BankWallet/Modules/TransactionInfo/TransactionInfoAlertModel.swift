import UIKit
import GrouviActionSheet

class TransactionInfoAlertModel: BaseAlertModel {

    init(transaction: TransactionViewItem, onCopyFromAddress: (() -> ())? = nil, onFullInfo: (() -> ())? = nil) {
        let titleItem = TransactionTitleItem(transaction: transaction, tag: 0, required: true, onIdTap: {
            onFullInfo?()
        })

        super.init()
        hideInBackground = false

        addItemView(titleItem)

        let amountItem = TransactionAmountItem(transaction: transaction, tag: 1, required: true)
        addItemView(amountItem)

        let fromHashItem = TransactionFromToHashItem(transaction: transaction, tag: 3, required: true, onHashTap: {
            onCopyFromAddress?()
        })
        addItemView(fromHashItem)

        let statusItem = TransactionStatusItem(transaction: transaction, tag: 2, required: true)
        addItemView(statusItem)

        let closeItem = TransactionCloseItem(tag: 6, required: true, onTap: { [weak self] in
            self?.dismiss?(true)
        })
        addItemView(closeItem)
    }

}
