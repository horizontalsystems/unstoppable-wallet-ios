import UIKit
import GrouviActionSheet

class DepositAlertModel: BaseAlertModel {

    let delegate: IDepositViewDelegate

    init(viewDelegate: IDepositViewDelegate, coinCode: CoinCode?) {
        self.delegate = viewDelegate

        super.init()

        let items = delegate.addressItems(forCoin: coinCode)

        hideInBackground = false

        var currentPage = 0
        var pagingItem: PagingDotsItem?

        let depositItem = DepositCollectionItem(addresses: items, tag: 0, onPageChange: { index in
            currentPage = index
            pagingItem?.currentPage = index
            pagingItem?.updateView?()
        }, onCopy: { [weak self] item in
            self?.delegate.onCopy(addressItem: item)
        })
        addItemView(depositItem)

        if items.count > 1 {
            pagingItem = PagingDotsItem(pagesCount: 3, tag: 1, required: true)
            addItemView(pagingItem!)
        }

        let shareItem = DepositShareButtonItem(tag: 2, onTap: { [weak self] in
            self?.delegate.onShare(addressItem: items[currentPage])
        })
        addItemView(shareItem)
    }

}

extension DepositAlertModel: IDepositView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
