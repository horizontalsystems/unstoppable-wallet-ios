import UIKit
import GrouviActionSheet

class DepositAlertModel: BaseAlertModel {

    init(addresses: [AddressItem], onCopy: ((Int) -> ())? = nil, onShare: ((Int) -> ())? = nil) {
        super.init()
        hideInBackground = false

        var currentPage = 0
        var pagingItem: PagingDotsItem?
        let depositItem = DepositCollectionItem(addresses: addresses, tag: 0, required: true, onPageChange: { index in
            currentPage = index
            pagingItem?.currentPage = index
            pagingItem?.updateView?()
        })
        addItemView(depositItem)

        let copyItem = CopyItem(tag: 1, required: true, onCopy: {
            onCopy?(currentPage)
        })
        addItemView(copyItem)

        if addresses.count > 1 {
            pagingItem = PagingDotsItem(pagesCount: 3, tag: 0, required: true)
            addItemView(pagingItem!)
        }

        let shareItem = DepositShareButtonItem(tag: 4, required: true, onTap: {
            onShare?(currentPage)
        })
        addItemView(shareItem)
    }

}
