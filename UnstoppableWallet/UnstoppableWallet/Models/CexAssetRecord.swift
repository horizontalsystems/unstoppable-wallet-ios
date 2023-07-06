import Foundation
import GRDB
import MarketKit

class CexAssetRecord: Record {
    let accountId: String
    let id: String
    let name: String
    let freeBalance: Decimal
    let lockedBalance: Decimal
    let depositEnabled: Bool
    let withdrawEnabled: Bool
    let depositNetworks: [CexDepositNetworkRaw]
    let withdrawNetworks: [CexWithdrawNetworkRaw]
    let coinUid: String?

    init(accountId: String, id: String, name: String, freeBalance: Decimal, lockedBalance: Decimal, depositEnabled: Bool, withdrawEnabled: Bool, depositNetworks: [CexDepositNetworkRaw], withdrawNetworks: [CexWithdrawNetworkRaw], coinUid: String?) {
        self.accountId = accountId
        self.id = id
        self.name = name
        self.freeBalance = freeBalance
        self.lockedBalance = lockedBalance
        self.depositEnabled = depositEnabled
        self.withdrawEnabled = withdrawEnabled
        self.withdrawNetworks = withdrawNetworks
        self.depositNetworks = depositNetworks
        self.coinUid = coinUid

        super.init()
    }

    override class var databaseTableName: String {
        "CexAssetRecord"
    }

    enum Columns: String, ColumnExpression {
        case accountId, id, name, freeBalance, lockedBalance, depositEnabled, withdrawEnabled, depositNetworks, withdrawNetworks, coinUid
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        id = row[Columns.id]
        name = row[Columns.name]
        freeBalance = row[Columns.freeBalance]
        lockedBalance = row[Columns.lockedBalance]
        depositEnabled = row[Columns.depositEnabled]
        withdrawEnabled = row[Columns.withdrawEnabled]
        let rawDepositNetworks: String? = row[Columns.depositNetworks]
        depositNetworks = rawDepositNetworks.flatMap { [CexDepositNetworkRaw](JSONString: $0) } ?? []
        let rawWithdrawNetworks: String? = row[Columns.withdrawNetworks]
        withdrawNetworks = rawWithdrawNetworks.flatMap { [CexWithdrawNetworkRaw](JSONString: $0) } ?? []
        coinUid = row[Columns.coinUid]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.freeBalance] = freeBalance
        container[Columns.lockedBalance] = lockedBalance
        container[Columns.depositEnabled] = depositEnabled
        container[Columns.withdrawEnabled] = withdrawEnabled
        container[Columns.depositNetworks] = depositNetworks.toJSONString()
        container[Columns.withdrawNetworks] = withdrawNetworks.toJSONString()
        container[Columns.coinUid] = coinUid
    }

}
