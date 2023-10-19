import Foundation
import GRDB

class EnabledWalletCache: Record {
    let tokenQueryId: String
    let accountId: String
    let balances: Data

    init(wallet: Wallet, balanceData: BalanceData) {
        tokenQueryId = wallet.token.tokenQuery.id
        accountId = wallet.account.id
        balances = balanceData.encoded

        super.init()
    }

    var balanceData: BalanceData {
        do {
            let balanceData = try BalanceData.instance(data: balances)
            return balanceData
        } catch {
            return BalanceData(available: 0)
        }
    }

    override class var databaseTableName: String {
        "enabled_wallet_caches"
    }

    enum Columns: String, ColumnExpression {
        case tokenQueryId, accountId, balances
    }

    required init(row: Row) {
        tokenQueryId = row[Columns.tokenQueryId]
        accountId = row[Columns.accountId]
        balances = row[Columns.balances]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.tokenQueryId] = tokenQueryId
        container[Columns.accountId] = accountId
        container[Columns.balances] = balances
    }

}
