import GRDB

class RestoreSettingRecord: Record {
    let accountId: String
    let blockchainUid: String
    let key: String
    let value: String

    init(accountId: String, blockchainUid: String, key: String, value: String) {
        self.accountId = accountId
        self.blockchainUid = blockchainUid
        self.key = key
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        "restore_settings"
    }

    enum Columns: String, ColumnExpression {
        case accountId, blockchainUid, key, value
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        blockchainUid = row[Columns.blockchainUid]
        key = row[Columns.key]
        value = row[Columns.value]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.blockchainUid] = blockchainUid
        container[Columns.key] = key
        container[Columns.value] = value
    }

}
