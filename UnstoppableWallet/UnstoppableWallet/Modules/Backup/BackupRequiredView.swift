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
            items: [
                .title(icon: .warning, title: title),
                .text(text: description),
                .buttonGroup(.init(buttons: [
                    .init(style: .gray, title: "backup_prompt.backup_manual".localized, icon: "edit_24") {
                        isPresented = false

                        Coordinator.shared.present { _ in
                            BackupView(account: account).ignoresSafeArea()
                        }
                        stat(page: statPage, event: .open(page: .manualBackup))
                    },
                    .init(style: .transparent, title: "backup_prompt.backup_cloud".localized, icon: "icloud_24") {
                        isPresented = false

                        Coordinator.shared.present { _ in
                            ICloudBackupTermsView(account: account).ignoresSafeArea()
                        }
                        stat(page: statPage, event: .open(page: .cloudBackup))
                    },
                ])),
            ],
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
