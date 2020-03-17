import GRDB

class BlockchainSettingRecord: Record {
    let coinType: String

    var derivation: String?
    var syncMode: String?

    init(coinType: String, derivation: String?, syncMode: String?) {
        self.coinType = coinType

        self.derivation = derivation
        self.syncMode = syncMode

        super.init()
    }

    override class var databaseTableName: String {
        "blockchain_settings"
    }

    enum Columns: String, ColumnExpression {
        case coinType, derivation, syncMode
    }

    required init(row: Row) {
        coinType = row[Columns.coinType]
        derivation = row[Columns.derivation]
        syncMode = row[Columns.syncMode]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinType] = coinType
        container[Columns.derivation] = derivation
        container[Columns.syncMode] = syncMode
    }

}
