import SwiftUI

struct BackupAppModule {
    static func view(onDismiss: (() -> ())?) -> some View {
        let viewModel = BackupAppViewModel(
                accountManager: App.shared.accountManager,
                contactManager: App.shared.contactManager,
                cloudBackupManager: App.shared.cloudBackupManager,
                favoritesManager: App.shared.favoritesManager,
                evmSyncSourceManager: App.shared.evmSyncSourceManager
        )

        return BackupTypeView(viewModel: viewModel, onDismiss: onDismiss)
    }
}

extension BackupAppModule {
    enum Destination: String, CaseIterable, Identifiable {
        case cloud
        case local

        var id: Self {
            self
        }

        var backupDisclaimer: BackupDestinationDisclaimer {
            switch self {
            case .cloud:
                return BackupDestinationDisclaimer(
                        title: "backup_app.backup.disclaimer.cloud.title".localized,
                        highlightedDescription:  "backup_app.backup.disclaimer.cloud.description".localized,
                        selectedCheckboxText:  "backup_app.backup.disclaimer.cloud.checkbox_label".localized,
                        buttonTitle: "button.next".localized
                )
            case .local:
                return BackupDestinationDisclaimer(
                        title: "backup_app.backup.disclaimer.file.title".localized,
                        highlightedDescription:  "backup_app.backup.disclaimer.file.description".localized,
                        selectedCheckboxText:  "backup_app.backup.disclaimer.file.checkbox_label".localized,
                        buttonTitle: "button.next".localized
                )
            }
        }
    }

    struct BackupDestinationDisclaimer {
        let title: String
        let highlightedDescription: String
        let selectedCheckboxText: String
        let buttonTitle: String
    }
}

extension BackupAppModule {
    static func items(watchAccountCount: Int, watchlistCount: Int, contactAddressCount: Int, blockchainSourcesCount: Int) -> [BackupAppModule.Item] {
        var items = [Item]()

        if watchAccountCount != 0 {
            items.append(BackupAppModule.Item(
                    title: "backup_app.backup_list.other.watch_account.title".localized,
                    value: watchAccountCount.description
            ))
        }

        if watchlistCount != 0 {
            items.append(BackupAppModule.Item(
                    title: "backup_app.backup_list.other.watchlist.title".localized,
                    value: watchlistCount.description
            ))
        }

        if contactAddressCount != 0 {
            items.append(BackupAppModule.Item(
                    title: "backup_app.backup_list.other.contacts.title".localized,
                    value: contactAddressCount.description
            ))
        }

        if blockchainSourcesCount != 0 {
            items.append(BackupAppModule.Item(
                    title: "backup_app.backup_list.other.blockchain_settings.title".localized,
                    value: blockchainSourcesCount.description
            ))
        }
        items.append(BackupAppModule.Item(
                title: "backup_app.backup_list.other.app_settings.title".localized,
                description: "backup_app.backup_list.other.app_settings.description".localized
        ))

        return items
    }

}
extension BackupAppModule {
    struct AccountItem: Comparable, Identifiable {
        let accountId: String
        let name: String
        let description: String
        let cautionType: CautionType?

        static func < (lhs: AccountItem, rhs: AccountItem) -> Bool {
            lhs.name < rhs.name
        }

        static func == (lhs: AccountItem, rhs: AccountItem) -> Bool {
            lhs.accountId == rhs.accountId
        }

        var id: String {
            accountId
        }
    }

    struct Item: Identifiable {
        let title: String
        let value: String?
        let description: String?

        init(title: String, value: String? = nil, description: String? = nil) {
            self.title = title
            self.value = value
            self.description = description
        }

        var id: String {
            title
        }
    }
}