import UIKit
import GrouviActionSheet

class DepositCollectionItem: BaseActionItem {

    var addresses: [AddressItem]
    var onPageChange: ((Int) -> ())?

    init(addresses: [AddressItem], tag: Int? = nil, hidden: Bool = false, required: Bool = false, onPageChange: ((Int) -> ())? = nil) {
        self.addresses = addresses
        self.onPageChange = onPageChange

        super.init(cellType: DepositCollectionItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = DepositTheme.collectionHeight
    }

}
