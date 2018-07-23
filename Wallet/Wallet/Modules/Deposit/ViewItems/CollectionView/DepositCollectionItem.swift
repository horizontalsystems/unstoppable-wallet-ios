import UIKit
import GrouviActionSheet

class DepositCollectionItem: BaseActionItem {

    var wallets: [String]
    var onPageChange: ((Int) -> ())?

    init(wallets: [String], tag: Int? = nil, hidden: Bool = false, required: Bool = false, onPageChange: ((Int) -> ())? = nil) {
        self.wallets = wallets
        self.onPageChange = onPageChange

        super.init(cellType: DepositCollectionItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = DepositTheme.collectionHeight
    }

}
