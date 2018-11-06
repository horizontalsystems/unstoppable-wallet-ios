import UIKit
import GrouviActionSheet

class DepositAlertModel: BaseAlertModel {

    let delegate: IDepositViewDelegate

    init(viewDelegate: IDepositViewDelegate, coin: Coin?) {
        self.delegate = viewDelegate

        super.init()

        let items = delegate.addressItems(forCoin: coin)

        hideInBackground = false

        var currentPage = 0
        var pagingItem: PagingDotsItem?

        let depositItem = DepositCollectionItem(addresses: items, tag: 0, required: true, onPageChange: { index in
            currentPage = index
            pagingItem?.currentPage = index
            pagingItem?.updateView?()
        })
        addItemView(depositItem)

        if items.count > 1 {
            pagingItem = PagingDotsItem(pagesCount: 3, tag: 1, required: true)
            addItemView(pagingItem!)
        }

        let shareItem = DepositCopyButtonItem(tag: 2, required: true, onTap: { [weak self] in
            self?.delegate.onCopy(addressItem: items[currentPage])
        })
        addItemView(shareItem)
    }

}

extension DepositAlertModel: IDepositView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
