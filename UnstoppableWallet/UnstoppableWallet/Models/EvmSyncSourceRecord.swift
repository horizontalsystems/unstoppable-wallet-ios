import GRDB

class EvmSyncSourceRecord: Record {
    let blockchainTypeUid: String
    let url: String
    let auth: String?

    init(blockchainTypeUid: String, url: String, auth: String?) {
        self.blockchainTypeUid = blockchainTypeUid
        self.url = url
        self.auth = auth

        super.init()
    }

    override class var databaseTableName: String {
        "evmSyncSource"
    }

    enum Columns: String, ColumnExpression {
        case blockchainTypeUid, name, url, auth
    }

    required init(row: Row) {
        blockchainTypeUid = row[Columns.blockchainTypeUid]
        url = row[Columns.url]
        auth = row[Columns.auth]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.blockchainTypeUid] = blockchainTypeUid
        container[Columns.url] = url
        container[Columns.auth] = auth
    }

}
