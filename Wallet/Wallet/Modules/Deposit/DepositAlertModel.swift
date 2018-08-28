import UIKit
import GrouviActionSheet

class DepositAlertModel: BaseAlertModel {

    let delegate: IDepositViewDelegate

    init(viewDelegate: IDepositViewDelegate, adapters: [IAdapter]) {
        self.delegate = viewDelegate

        super.init()
        delegate.viewDidLoad()

        var pagingItem: PagingDotsItem?
        let depositItem = DepositCollectionItem(wallets: adapters.map { $0.receiveAddress }, tag: 0, required: true, onPageChange: { index in
            pagingItem?.currentPage = index
            pagingItem?.updateView?()
        })
        addItemView(depositItem)

        let copyItem = CopyItem(tag: 1, required: true, onCopy: {
            UIPasteboard.general.string = adapters.first?.receiveAddress
            print("onCopy")
        })
        addItemView(copyItem)

        if adapters.count > 1 {
            pagingItem = PagingDotsItem(pagesCount: 3, tag: 0, required: true)
            addItemView(pagingItem!)
        }

        let shareItem = DepositShareButtonItem(tag: 4, required: true, onTap: {
            print("share")
        })
        addItemView(shareItem)
    }

}

extension DepositAlertModel: IDepositView {

}
