import MarketKit

struct InitialSyncSetting {
    let coinType: CoinType
    let syncMode: SyncMode
}

extension InitialSyncSetting: Equatable {

    public static func ==(lhs: InitialSyncSetting, rhs: InitialSyncSetting) -> Bool {
        lhs.coinType == rhs.coinType && lhs.syncMode == rhs.syncMode
    }

}
