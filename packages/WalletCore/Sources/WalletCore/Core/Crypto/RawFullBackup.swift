import Foundation
import MarketKit

struct RawFullBackup {
    var accounts: [RawWalletBackup]
    let watchlistIds: [String]
    let contacts: [BackupContact]
    let settings: SettingsBackup
    let customSyncSources: [EvmSyncSourceRecord]
    let customMoneroNodes: [MoneroNodeRecord]
    let customZanoNodes: [ZanoNodeRecord]
    let customZcashNodes: [ZcashNodeRecord]
    let sections: Set<BackupSection>?
}

struct RawWalletBackup {
    let account: Account
    let enabledWallets: [WalletBackup.EnabledWallet]
    // settings that live in the account data rather than in an enabled wallet: a Monero watch
    // account's height, which Android writes there and reads from there
    var restoreSettings: [BlockchainType: RestoreSettings] = [:]
}
