import UIKit
import GrouviActionSheet

class DepositAlertModel: BaseAlertModel {

    let delegate: IDepositViewDelegate

    init(viewDelegate: IDepositViewDelegate) {
        self.delegate = viewDelegate

        super.init()
        delegate.viewDidLoad()

        let wallets = ["S4DL2JHF6BS3JD1LUR76FNR8EI4", "23SD5FIBY2I4EBT6RY6V7EK7S8DH", "23SD5FIBY2I4EBT6RY6V7EK7S8DH"]
//        let wallets = ["23SD5FIBY2I4EBT6RY6V7EK7S8DH"]

        var pagingItem: PagingDotsItem?
        let depositItem = DepositCollectionItem(wallets: wallets, tag: 0, required: true, onPageChange: { [weak self] index in
            pagingItem?.currentPage = index
            self?.reload?()
        })
        addItemView(depositItem)

        let copyItem = CopyItem(tag: 1, required: true, onCopy: {
            print("onCopy")
        })
        addItemView(copyItem)

        if wallets.count > 1 {
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
