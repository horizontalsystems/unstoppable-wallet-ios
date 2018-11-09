import UIKit
import GrouviActionSheet

class TransactionInfoAlertModel: BaseAlertModel {

    let delegate: ITransactionInfoViewDelegate

    init(delegate: ITransactionInfoViewDelegate, transactionHash: String) {
        self.delegate = delegate

        super.init()

        hideInBackground = false

        if let item = delegate.transactionViewItem(forTransactionHash: transactionHash) {
            let titleItem = TransactionTitleItem(item: item, tag: 0, required: true, onIdTap: {
                delegate.onCopy(value: item.transactionHash)
            })
            addItemView(titleItem)

            let amountItem = TransactionAmountItem(item: item, tag: 1, required: true)
            addItemView(amountItem)

            if let from = item.from {
                addItemView(TransactionFromToHashItem(title: "tx_info.bottom_sheet.from_hash".localized, value: from, tag: 2, required: true, onHashTap: {
                    delegate.onCopy(value: from)
                }))
            }

            if let to = item.to {
                addItemView(TransactionFromToHashItem(title: "tx_info.bottom_sheet.to_hash".localized, value: to, tag: 3, required: true, onHashTap: {
                    delegate.onCopy(value: to)
                }))
            }

            let statusItem = TransactionStatusItem(item: item, tag: 4, required: true)
            addItemView(statusItem)
        }

        let closeItem = TransactionCloseItem(tag: 5, required: true, onTap: { [weak self] in
            self?.dismiss?(true)
        })
        addItemView(closeItem)
    }

}

extension TransactionInfoAlertModel: ITransactionInfoView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
