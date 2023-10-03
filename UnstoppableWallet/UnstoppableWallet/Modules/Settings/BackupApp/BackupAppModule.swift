import SwiftUI

struct BackupAppModule {
    static func view(backupPresented: Binding<Bool>) -> some View {
        let viewModel = BackupAppViewModel(
                accountManager: App.shared.accountManager,
                contactManager: App.shared.contactManager,
                cloudBackupManager: App.shared.cloudBackupManager,
                favoritesManager: App.shared.favoritesManager,
                evmSyncSourceManager: App.shared.evmSyncSourceManager
        )

        return BackupTypeView(viewModel: viewModel, backupPresented: backupPresented)
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
                        title: "backup.disclaimer.cloud.title".localized,
                        highlightedDescription:  "backup.disclaimer.cloud.description".localized,
                        selectedCheckboxText:  "backup.disclaimer.cloud.checkbox_label".localized,
                        buttonTitle: "button.next".localized
                )
            case .local:
                return BackupDestinationDisclaimer(
                        title: "backup.disclaimer.file.title".localized,
                        highlightedDescription:  "backup.disclaimer.file.description".localized,
                        selectedCheckboxText:  "backup.disclaimer.file.checkbox_label".localized,
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
