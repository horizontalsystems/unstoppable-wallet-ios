enum TransactionDataSortMode: String, CaseIterable {
    case shuffle
    case bip69

    var title: String {
        "btc_transaction_sort_mode.\(self)".localized
    }

    var description: String {
        "btc_transaction_sort_mode.\(self).description".localized
    }

}
