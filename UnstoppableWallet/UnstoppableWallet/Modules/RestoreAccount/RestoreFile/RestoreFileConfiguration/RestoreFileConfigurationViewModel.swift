import Foundation
import Combine

class RestoreFileConfigurationViewModel {
    private let cloudBackupManager: CloudBackupManager
    private let appBackupProvider: AppBackupProvider
    private let rawBackup: RawFullBackup

    private let finishedSubject = PassthroughSubject<Bool, Never>()

    init(cloudBackupManager: CloudBackupManager, appBackupProvider: AppBackupProvider, rawBackup: RawFullBackup) {
        self.cloudBackupManager = cloudBackupManager
        self.appBackupProvider = appBackupProvider
        self.rawBackup = rawBackup
    }

    private func item(account: Account) -> BackupAppModule.AccountItem {
        var alertSubtitle: String?
        let hasAlertDescription = !(account.backedUp || cloudBackupManager.backedUp(uniqueId: account.type.uniqueId()))
        if account.nonStandard {
            alertSubtitle = "manage_accounts.migration_required".localized
        } else if hasAlertDescription {
            alertSubtitle = "manage_accounts.backup_required".localized
        }

        let showAlert = alertSubtitle != nil || account.nonRecommended

        let cautionType: CautionType? = showAlert ? .error : .none
        let description = alertSubtitle ?? account.type.detailedDescription

        return BackupAppModule.AccountItem(
                accountId: account.id,
                name: account.name,
                description: description,
                cautionType: cautionType
        )
    }
}

extension RestoreFileConfigurationViewModel {
    var accountItems: [BackupAppModule.AccountItem] {
        rawBackup
            .accounts
            .filter { !$0.account.watchAccount }
            .map { item(account: $0.account) }
    }

    var otherItems: [BackupAppModule.Item] {
        let contactAddressCount = rawBackup.contacts.count
        let watchAccounts = rawBackup
            .accounts
            .filter { $0.account.watchAccount }

        return BackupAppModule.items(
                watchAccountCount: watchAccounts.count,
                watchlistCount: rawBackup.watchlistIds.count,
                contactAddressCount: contactAddressCount,
                blockchainSourcesCount: rawBackup.customSyncSources.count
        )
    }

    func onTapRestore() {
        appBackupProvider.restore(raw: rawBackup)
        finishedSubject.send(true)
    }

    var finishedPublisher: AnyPublisher<Bool, Never> {
        finishedSubject.eraseToAnyPublisher()
    }
}
