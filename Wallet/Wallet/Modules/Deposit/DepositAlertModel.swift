import UIKit
import GrouviActionSheet

class DepositAlertModel: BaseAlertModel {

    let delegate: IDepositViewDelegate

    init(viewDelegate: IDepositViewDelegate) {
        self.delegate = viewDelegate

        super.init()
        delegate.viewDidLoad()

        let coins = ["S4DL2JHF6BS3JD1LUR76FNR8EI4", "23SD5FIBY2I4EBT6RY6V7EK7S8DH", "23SD5FIBY2I4EBT6RY6V7EK7S8DH"]
//        let coins = ["23SD5FIBY2I4EBT6RY6V7EK7S8DH"]

        var pagingItem: PagingDotsItem?
        let depositItem = DepositCollectionItem(wallets: coins, tag: 0, required: true, onPageChange: { index in
            pagingItem?.currentPage = index
            pagingItem?.updateView?()
        })
        addItemView(depositItem)

        let copyItem = CopyItem(tag: 1, required: true, onCopy: {
            print("onCopy")
        })
        addItemView(copyItem)

        if coins.count > 1 {
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
