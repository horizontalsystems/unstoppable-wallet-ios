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
    let networks: [CexNetworkRaw]
    let coinUid: String?

    init(accountId: String, id: String, name: String, freeBalance: Decimal, lockedBalance: Decimal, depositEnabled: Bool, withdrawEnabled: Bool, networks: [CexNetworkRaw], coinUid: String?) {
        self.accountId = accountId
        self.id = id
        self.name = name
        self.freeBalance = freeBalance
        self.lockedBalance = lockedBalance
        self.depositEnabled = depositEnabled
        self.withdrawEnabled = withdrawEnabled
        self.networks = networks
        self.coinUid = coinUid

        super.init()
    }

    override class var databaseTableName: String {
        "CexAssetRecord"
    }

    enum Columns: String, ColumnExpression {
        case accountId, id, name, freeBalance, lockedBalance, depositEnabled, withdrawEnabled, networks, coinUid
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        id = row[Columns.id]
        name = row[Columns.name]
        freeBalance = row[Columns.freeBalance]
        lockedBalance = row[Columns.lockedBalance]
        depositEnabled = row[Columns.depositEnabled]
        withdrawEnabled = row[Columns.withdrawEnabled]
        let rawNetworks: String? = row[Columns.networks]
        networks = rawNetworks.flatMap { [CexNetworkRaw](JSONString: $0) } ?? []
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
        container[Columns.networks] = networks.toJSONString()
        container[Columns.coinUid] = coinUid
    }

}
