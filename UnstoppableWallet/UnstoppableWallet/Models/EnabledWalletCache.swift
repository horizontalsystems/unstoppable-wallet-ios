import Foundation
import GRDB

class EnabledWalletCache: Record {
    let tokenQueryId: String
    let accountId: String
    let total: Decimal
    let available: Decimal

    init(wallet: Wallet, balanceData: BalanceData) {
        tokenQueryId = wallet.token.tokenQuery.id
        accountId = wallet.account.id
        total = balanceData.total
        available = balanceData.available

        super.init()
    }

    var balanceData: BalanceData {
        BalanceData(total: total, available: available)
    }

    override class var databaseTableName: String {
        "enabled_wallet_caches"
    }

    enum Columns: String, ColumnExpression {
        case tokenQueryId, accountId, total, available
    }

    required init(row: Row) throws {
        tokenQueryId = row[Columns.tokenQueryId]
        accountId = row[Columns.accountId]
        total = row[Columns.total]
        available = row[Columns.available]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.tokenQueryId] = tokenQueryId
        container[Columns.accountId] = accountId
        container[Columns.total] = total
        container[Columns.available] = available
    }
}
