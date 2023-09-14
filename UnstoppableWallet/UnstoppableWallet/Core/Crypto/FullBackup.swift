import Foundation

struct FullBackup {
    let wallets: [WalletBackup]
    let watchlistIds: [String]
    let contacts: ContactBook?
    let appearance: AppearanceBackup?
}
