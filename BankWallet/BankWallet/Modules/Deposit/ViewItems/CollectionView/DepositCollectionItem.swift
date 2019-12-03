import UIKit
import ActionSheet

class DepositCollectionItem: BaseActionItem {
    var addresses: [AddressItem]
    var onPageChange: ((Int) -> ())?
    var onCopy: (() -> ())?
    var onClose: (() -> ())?

    init(addresses: [AddressItem], tag: Int, onPageChange: @escaping (Int) -> (), onCopy: @escaping () -> (), onClose: @escaping () -> ()) {
        self.addresses = addresses
        self.onPageChange = onPageChange
        self.onCopy = onCopy
        self.onClose = onClose

        super.init(cellType: DepositCollectionItemView.self, tag: tag, required: true)

        showSeparator = false
        height = 273
    }

}
