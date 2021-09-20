import Foundation
import GRDB

class EnabledWalletCache: Record {
    let coinId: String
    let coinSettingsId: String
    let accountId: String
    let balance: Decimal
    let balanceLocked: Decimal

    init(wallet: Wallet, balanceData: BalanceData) {
        coinId = wallet.coinType.id
        coinSettingsId = wallet.coinSettings.id
        accountId = wallet.account.id
        balance = balanceData.balance
        balanceLocked = balanceData.balanceLocked

        super.init()
    }

    var balanceData: BalanceData {
        BalanceData(balance: balance, balanceLocked: balanceLocked)
    }

    override class var databaseTableName: String {
        "enabled_wallet_caches"
    }

    enum Columns: String, ColumnExpression {
        case coinId, coinSettingsId, accountId, balance, balanceLocked
    }

    required init(row: Row) {
        coinId = row[Columns.coinId]
        coinSettingsId = row[Columns.coinSettingsId]
        accountId = row[Columns.accountId]
        balance = row[Columns.balance]
        balanceLocked = row[Columns.balanceLocked]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinId
        container[Columns.coinSettingsId] = coinSettingsId
        container[Columns.accountId] = accountId
        container[Columns.balance] = balance
        container[Columns.balanceLocked] = balanceLocked
    }

}
