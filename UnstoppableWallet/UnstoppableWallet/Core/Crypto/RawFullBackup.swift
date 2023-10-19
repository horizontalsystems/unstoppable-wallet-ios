import Foundation

struct RawFullBackup {
    var accounts: [RawWalletBackup]
    let watchlistIds: [String]
    let contacts: [BackupContact]
    let settings: SettingsBackup
    let customSyncSources: [EvmSyncSourceRecord]
}

struct RawWalletBackup {
    let account: Account
    let enabledWallets: [WalletBackup.EnabledWallet]
}
