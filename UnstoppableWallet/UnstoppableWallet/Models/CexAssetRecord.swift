import Foundation
import GRDB
import MarketKit

class CexAssetRecord: Record {
    let accountId: String
    let id: String
    let freeBalance: Decimal
    let lockedBalance: Decimal
    let networks: [CexNetworkRaw]
    let coinUid: String?

    init(accountId: String, id: String, freeBalance: Decimal, lockedBalance: Decimal, networks: [CexNetworkRaw], coinUid: String?) {
        self.accountId = accountId
        self.id = id
        self.freeBalance = freeBalance
        self.lockedBalance = lockedBalance
        self.networks = networks
        self.coinUid = coinUid

        super.init()
    }

    override class var databaseTableName: String {
        "CexAssetRecord"
    }

    enum Columns: String, ColumnExpression {
        case accountId, id, freeBalance, lockedBalance, networks, coinUid
    }

    required init(row: Row) {
        accountId = row[Columns.accountId]
        id = row[Columns.id]
        freeBalance = row[Columns.freeBalance]
        lockedBalance = row[Columns.lockedBalance]
        let rawNetworks: String? = row[Columns.networks]
        networks = rawNetworks.flatMap { [CexNetworkRaw](JSONString: $0) } ?? []
        coinUid = row[Columns.coinUid]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.id] = id
        container[Columns.freeBalance] = freeBalance
        container[Columns.lockedBalance] = lockedBalance
        container[Columns.networks] = networks.toJSONString()
        container[Columns.coinUid] = coinUid
    }

}
