import Foundation

struct CexAssetResponse {
    let id: String
    let name: String
    let freeBalance: Decimal
    let lockedBalance: Decimal
    let depositEnabled: Bool
    let withdrawEnabled: Bool
    let depositNetworks: [CexDepositNetworkRaw]
    let withdrawNetworks: [CexWithdrawNetworkRaw]
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
                depositNetworks: depositNetworks,
                withdrawNetworks: withdrawNetworks,
                coinUid: coinUid
        )
    }

}
