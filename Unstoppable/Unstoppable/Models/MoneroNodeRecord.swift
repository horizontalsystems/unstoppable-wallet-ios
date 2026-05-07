import GRDB

class MoneroNodeRecord: Record {
    let blockchainTypeUid: String
    let url: String
    let isTrusted: Bool
    let login: String?
    let password: String?

    init(blockchainTypeUid: String, url: String, isTrusted: Bool, login: String?, password: String?) {
        self.blockchainTypeUid = blockchainTypeUid
        self.url = url
        self.isTrusted = isTrusted
        self.login = login
        self.password = password

        super.init()
    }

    override class var databaseTableName: String {
        "moneroNodes"
    }

    enum Columns: String, ColumnExpression {
        case blockchainTypeUid, name, url, isTrusted, login, password
    }

    required init(row: Row) throws {
        blockchainTypeUid = row[Columns.blockchainTypeUid]
        url = row[Columns.url]
        isTrusted = row[Columns.isTrusted]
        login = row[Columns.login]
        password = row[Columns.password]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.blockchainTypeUid] = blockchainTypeUid
        container[Columns.url] = url
        container[Columns.isTrusted] = isTrusted
        container[Columns.login] = login
        container[Columns.password] = password
    }
}
