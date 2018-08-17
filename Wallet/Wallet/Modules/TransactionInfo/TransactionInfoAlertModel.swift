import UIKit
import GrouviActionSheet

class TransactionInfoAlertModel: BaseAlertModel {

    init(transaction: TransactionRecordViewItem, onCopyFromAddress: (() -> ())? = nil, onFullInfo: (() -> ())? = nil) {
        let titleItem = TransactionTitleItem(transaction: transaction, tag: 0, required: true, onInfo: {
            onFullInfo?()
        })

        super.init()

        addItemView(titleItem)

        let amountItem = TransactionAmountItem(transaction: transaction, tag: 1, required: true)
        addItemView(amountItem)

        let statusItem = TransactionStatusItem(transaction: transaction, tag: 2, required: true)
        addItemView(statusItem)

        let idHashItem = TransactionIDHashItem(transaction: transaction, tag: 5, required: true)
        idHashItem.showSeparator = false
        addItemView(idHashItem)

        let fiatAmountItem = TransactionFiatAmountItem(transaction: transaction, tag: 4, required: true)
        addItemView(fiatAmountItem)

        let fromHashItem = TransactionFromHashItem(transaction: transaction, tag: 3, required: true) { _ in
            onCopyFromAddress?()
        }
        addItemView(fromHashItem)

        let closeItem = TransactionCloseItem(tag: 6, required: true, onTap: { [weak self] in
            self?.dismiss?(true)
        })
        addItemView(closeItem)
    }

}
