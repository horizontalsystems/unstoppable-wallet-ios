import SwiftUI

struct BackupRequiredView: View {
    let account: Account
    let title: String
    let description: String
    let cancelText: String
    let statPage: StatPage

    @Binding var isPresented: Bool

    var body: some View {
        BottomSheetView(
            icon: .warning,
            title: title,
            items: [
                .highlightedDescription(text: description),
            ],
            buttons: [
                .init(style: .yellow, title: "backup_prompt.backup_manual".localized, icon: "edit_24") {
                    isPresented = false

                    Coordinator.shared.present { _ in
                        BackupView(account: account).ignoresSafeArea()
                    }
                    stat(page: statPage, event: .open(page: .manualBackup))
                },
                .init(style: .gray, title: "backup_prompt.backup_cloud".localized, icon: "icloud_24") {
                    isPresented = false

                    Coordinator.shared.present { _ in
                        ICloudBackupTermsView(account: account).ignoresSafeArea()
                    }
                    stat(page: statPage, event: .open(page: .cloudBackup))
                },
                .init(style: .transparent, title: cancelText) {
                    isPresented = false
                },
            ],
            isPresented: $isPresented
        )
    }

    static func afterCreate(account: Account, isPresented: Binding<Bool>) -> BackupRequiredView {
        BackupRequiredView(
            account: account,
            title: "backup_prompt.backup_recovery_phrase".localized,
            description: "backup_prompt.warning".localized,
            cancelText: "backup_prompt.later".localized,
            statPage: .backupPromptAfterCreate,
            isPresented: isPresented
        )
    }

    static func prompt(account: Account, description: String, isPresented: Binding<Bool>) -> BackupRequiredView {
        BackupRequiredView(
            account: account,
            title: "backup_prompt.backup_required".localized,
            description: description,
            cancelText: "button.cancel".localized,
            statPage: .backupRequired,
            isPresented: isPresented
        )
    }
}
