class TransactionDataSortModeSettingManager {
    private let storage: ILocalStorage

    init(storage: ILocalStorage) {
        self.storage = storage
    }

}

extension TransactionDataSortModeSettingManager: ITransactionDataSortTypeSettingManager {

    var setting: TransactionDataSortMode {
        storage.transactionDataSortMode ?? .shuffle
    }

    func save(setting: TransactionDataSortMode) {
        storage.transactionDataSortMode = setting
    }

}
