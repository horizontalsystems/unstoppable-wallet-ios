import UIKit
import GrouviActionSheet

class DepositCollectionItem: BaseActionItem {

    var wallets: [String]

    init(wallets: [String], tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        self.wallets = wallets

        super.init(cellType: DepositCollectionItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = DepositTheme.collectionHeight
    }

}
