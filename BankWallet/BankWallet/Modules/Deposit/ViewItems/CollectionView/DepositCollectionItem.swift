import UIKit
import ActionSheet

class DepositCollectionItem: BaseActionItem {

    var addresses: [AddressItem]
    var onPageChange: ((Int) -> ())?
    var onCopy: (() -> ())?

    init(addresses: [AddressItem], tag: Int, onPageChange: @escaping (Int) -> (), onCopy: @escaping () -> ()) {
        self.addresses = addresses
        self.onPageChange = onPageChange
        self.onCopy = onCopy

        super.init(cellType: DepositCollectionItemView.self, tag: tag, required: true)

        showSeparator = false
        height = DepositTheme.collectionHeight
    }

}
