import GRDB

class CoinRecord: Record {
    let id: String
    let title: String
    let code: String
    let decimal: Int
    let tokenType: String

    var erc20Address: String?

    init(id: String, title: String, code: String, decimal: Int, tokenType: String) {
        self.id = id
        self.title = title
        self.code = code
        self.decimal = decimal
        self.tokenType = tokenType

        super.init()
    }

    override class var databaseTableName: String {
        "coins"
    }

    enum Columns: String, ColumnExpression {
        case coinId, title, code, decimal, tokenType, erc20Address
    }

    required init(row: Row) {
        id = row[Columns.coinId]
        title = row[Columns.title]
        code = row[Columns.code]
        decimal = row[Columns.decimal]
        tokenType = row[Columns.tokenType]
        erc20Address = row[Columns.erc20Address]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = id
        container[Columns.title] = title
        container[Columns.code] = code
        container[Columns.decimal] = decimal
        container[Columns.tokenType] = tokenType
        container[Columns.erc20Address] = erc20Address
    }

}
