import UIKit
import GrouviActionSheet

class DepositCollectionItem: BaseActionItem {

    var addresses: [AddressItem]
    var onPageChange: ((Int) -> ())?
    var onCopy: ((AddressItem) -> ())?

    init(addresses: [AddressItem], tag: Int, onPageChange: @escaping (Int) -> (), onCopy: @escaping (AddressItem) -> ()) {
        self.addresses = addresses
        self.onPageChange = onPageChange
        self.onCopy = onCopy

        super.init(cellType: DepositCollectionItemView.self, tag: tag, required: true)

        showSeparator = false
        height = DepositTheme.collectionHeight
    }

}
