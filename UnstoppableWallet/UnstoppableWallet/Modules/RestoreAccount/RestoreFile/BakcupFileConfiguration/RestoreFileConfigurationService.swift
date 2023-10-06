import Foundation

class RestoreFileConfigurationService {
    private let contactBookManager: ContactBookManager
    private let fullBackup: FullBackup
    private let passphrase: String

    init(contactBookManager: ContactBookManager, fullBackup: FullBackup, passphrase: String) {
        self.contactBookManager = contactBookManager
        self.fullBackup = fullBackup
        self.passphrase = passphrase
    }
}

extension RestoreFileConfigurationService {
    var accountItems: [BackupAppModule.AccountItem] {
        []
//        let wallets = fullBackup
//            .wallets
//            .filter { !$0.walletBackup.type.isWatch }
//
//        wallets.map { wallet in
//            BackupAppModule.AccountItem(
//                    accountId: wallet.walletBackup.id,
//                    name: <#T##String##Swift.String#>,
//                    description: <#T##String##Swift.String#>,
//                    cautionType: <#T##CautionType?##Unstoppable_Dev.CautionType?#>
//            )
//        }
    }

    var otherItems: [BackupAppModule.Item] {
        let watchAccountCount = fullBackup
            .wallets
            .filter { $0.walletBackup.type.isWatch }
            .count

        let contacts = fullBackup.contacts.flatMap { try? ContactBookManager.encode(crypto: $0, passphrase: passphrase) }
        let contactAddressCount = (contacts ?? []).reduce(into: 0) { $0 += $1.addresses.count }

        return BackupAppModule.items(
            watchAccountCount: watchAccountCount,
            watchlistCount: fullBackup.watchlistIds.count,
            contactAddressCount: contactAddressCount,
            blockchainSourcesCount: fullBackup.settings?.evmSyncSources.custom.count ?? 0
        )
    }
}
