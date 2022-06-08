import GRDB
import MarketKit

class BlockchainSettingRecord_v_0_24: Record {
    let coinType: String

    var key: String
    var value: String

    init(coinType: String, key: String, value: String) {
        self.coinType = coinType

        self.key = key
        self.value = value

        super.init()
    }

    override class var databaseTableName: String {
        "blockchain_settings"
    }

    enum Columns: String, ColumnExpression {
        case coinType, key, value
    }

    required init(row: Row) {
        coinType = row[Columns.coinType]
        key = row[Columns.key]
        value = row[Columns.value]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinType] = coinType
        container[Columns.key] = key
        container[Columns.value] = value
    }

}
