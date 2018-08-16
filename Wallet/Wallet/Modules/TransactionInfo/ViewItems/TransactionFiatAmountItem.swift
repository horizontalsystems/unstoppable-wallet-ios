import Foundation
import GrouviActionSheet

class TransactionFiatAmountItem: TransactionInfoBaseValueItem {

    init(transaction: TransactionRecordViewItem, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        super.init(tag: tag, hidden: hidden, required: required)

        title = "tx_info.bottom_sheet.value_when_received".localized
        //stab
        value = CurrencyHelper.instance.formattedValue(for: CurrencyValue(currency: DollarCurrency(), value: 342))
    }

}
