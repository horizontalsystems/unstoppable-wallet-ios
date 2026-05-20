import GRDB
import MarketKit

public class EnabledWallet: Record {
    public let tokenQueryId: String
    public let accountId: String

    public let coinName: String?
    public let coinCode: String?
    public let coinImage: String?
    public let tokenDecimals: Int?

    public init(tokenQueryId: String, accountId: String, coinName: String? = nil, coinCode: String? = nil, coinImage: String? = nil, tokenDecimals: Int? = nil) {
        self.tokenQueryId = tokenQueryId
        self.accountId = accountId
        self.coinName = coinName
        self.coinCode = coinCode
        self.coinImage = coinImage
        self.tokenDecimals = tokenDecimals

        super.init()
    }

    override public class var databaseTableName: String {
        "enabled_wallets"
    }

    public enum Columns: String, ColumnExpression {
        case tokenQueryId, accountId, coinName, coinCode, coinImage, tokenDecimals
    }

    public required init(row: Row) throws {
        tokenQueryId = row[Columns.tokenQueryId]
        accountId = row[Columns.accountId]
        coinName = row[Columns.coinName]
        coinCode = row[Columns.coinCode]
        coinImage = row[Columns.coinImage]
        tokenDecimals = row[Columns.tokenDecimals]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) {
        container[Columns.tokenQueryId] = tokenQueryId
        container[Columns.accountId] = accountId
        container[Columns.coinName] = coinName
        container[Columns.coinCode] = coinCode
        container[Columns.coinImage] = coinImage
        container[Columns.tokenDecimals] = tokenDecimals
    }
}
