import Foundation
import GRDB

class EnabledWalletCache_v_0_36: Record {
    let tokenQueryId: String
    let accountId: String
    let balance: Decimal
    let balanceLocked: Decimal
    let balances: Data

    init(wallet: Wallet, balanceData: BalanceData) {
        tokenQueryId = wallet.token.tokenQuery.id
        accountId = wallet.account.id
        balance = balanceData.available
        balanceLocked = 0

        balances = Data()

        super.init()
    }

    var balanceData: BalanceData {
        BalanceData(available: balance)
    }

    override class var databaseTableName: String {
        "enabled_wallet_caches"
    }

    enum Columns: String, ColumnExpression {
        case tokenQueryId, accountId, balance, balanceLocked // todo: migration - remove coinSettingsId
    }

    required init(row: Row) {
        tokenQueryId = row[Columns.tokenQueryId]
        accountId = row[Columns.accountId]
        balance = row[Columns.balance]
        balanceLocked = row[Columns.balanceLocked]
        balances = Data()

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.tokenQueryId] = tokenQueryId
        container[Columns.accountId] = accountId
        container[Columns.balance] = balance
        container[Columns.balanceLocked] = balanceLocked
    }

}
