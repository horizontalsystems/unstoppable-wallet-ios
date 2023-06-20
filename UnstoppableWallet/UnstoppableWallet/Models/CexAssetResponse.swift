import Foundation

struct CexAssetResponse {
    let id: String
    let freeBalance: Decimal
    let lockedBalance: Decimal
    let networks: [CexNetworkRaw]
    let coinUid: String?

    func record(accountId: String) -> CexAssetRecord {
        CexAssetRecord(
                accountId: accountId,
                id: id,
                freeBalance: freeBalance,
                lockedBalance: lockedBalance,
                networks: networks,
                coinUid: coinUid
        )
    }

}
