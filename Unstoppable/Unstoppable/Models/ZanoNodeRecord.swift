import GRDB

class ZanoNodeRecord: Record {
    let blockchainTypeUid: String
    let url: String

    init(blockchainTypeUid: String, url: String) {
        self.blockchainTypeUid = blockchainTypeUid
        self.url = url

        super.init()
    }

    override class var databaseTableName: String {
        "zanoNodes"
    }

    enum Columns: String, ColumnExpression {
        case blockchainTypeUid, url
    }

    required init(row: Row) throws {
        blockchainTypeUid = row[Columns.blockchainTypeUid]
        url = row[Columns.url]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.blockchainTypeUid] = blockchainTypeUid
        container[Columns.url] = url
    }
}
