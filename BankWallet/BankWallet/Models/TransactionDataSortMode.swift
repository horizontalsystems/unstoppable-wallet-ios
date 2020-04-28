enum TransactionDataSortMode: String, CaseIterable {
    case shuffle
    case bip69

    var title: String {
        "settings_privacy.sorting_\(self)".localized
    }

    var description: String {
        "settings_privacy.sorting_\(self).description".localized
    }

}
