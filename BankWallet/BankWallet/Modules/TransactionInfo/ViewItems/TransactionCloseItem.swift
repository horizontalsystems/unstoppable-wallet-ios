import Foundation
import GrouviActionSheet

class TransactionCloseItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return [RespondButton.State.active: TransactionInfoTheme.closeButtonBackground, RespondButton.State.selected: TransactionInfoTheme.closeButtonBackground] }
    override var textStyle: RespondButton.Style { return [RespondButton.State.active: TransactionInfoTheme.closeButtonTextColor, RespondButton.State.selected: TransactionInfoTheme.closeButtonTextColorSelected] }
    override var title: String { return "tx_info.alert_close".localized }

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onTap: @escaping (() -> ())) {
        super.init(cellType: TransactionCloseItemView.self, tag: tag, hidden: hidden, required: required)

        self.onTap = onTap
        height = TransactionInfoTheme.closeHeight
    }

}
