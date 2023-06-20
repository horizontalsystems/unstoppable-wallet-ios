import Foundation

struct CexAssetResponse {
    let id: String
    let name: String
    let freeBalance: Decimal
    let lockedBalance: Decimal
    let depositEnabled: Bool
    let withdrawEnabled: Bool
    let networks: [CexNetworkRaw]
    let coinUid: String?

    func record(accountId: String) -> CexAssetRecord {
        CexAssetRecord(
                accountId: accountId,
                id: id,
                name: name,
                freeBalance: freeBalance,
                lockedBalance: lockedBalance,
                depositEnabled: depositEnabled,
                withdrawEnabled: withdrawEnabled,
                networks: networks,
                coinUid: coinUid
        )
    }

}
