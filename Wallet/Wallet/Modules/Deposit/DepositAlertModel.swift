import UIKit
import GrouviActionSheet

class DepositAlertModel: BaseAlertModel {

    let delegate: IDepositViewDelegate


    init(viewDelegate: IDepositViewDelegate) {
        self.delegate = viewDelegate

        super.init()
        delegate.viewDidLoad()

        let depositItem = DepositCollectionItem(wallets: ["S4DL2JHF6BS3JD1LUR76FNR8EI4", "23SD5FIBY2I4EBT6RY6V7EK7S8DH"], tag: 0, required: true)
        addItemView(depositItem)

        let copyItem = CopyItem(tag: 1, required: true, onCopy: {
            print("onCopy")
        })
        addItemView(copyItem)

        let pagingItem = PagingDotsItem(pagesCount: 3, tag: 0, required: true)
        addItemView(pagingItem)

        let shareItem = DepositButtonItem(tag: 4, required: true, onTap: {
            print("share")
        })
        addItemView(shareItem)
    }

}

extension DepositAlertModel: IDepositView {

}
