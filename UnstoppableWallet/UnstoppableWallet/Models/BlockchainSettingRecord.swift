import GRDB
import MarketKit

class BlockchainSettingRecord: Record {
    let blockchainUid: String
    let key: String
    let value: String

    init(blockchainUid: String, key: String, value: String) {
        self.blockchainUid = blockchainUid
        self.key = key
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        "blockchain_settings"
    }

    enum Columns: String, ColumnExpression {
        case blockchainUid, key, value
    }

    required init(row: Row) {
        blockchainUid = row[Columns.blockchainUid]
        key = row[Columns.key]
        value = row[Columns.value]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.blockchainUid] = blockchainUid
        container[Columns.key] = key
        container[Columns.value] = value
    }

}
