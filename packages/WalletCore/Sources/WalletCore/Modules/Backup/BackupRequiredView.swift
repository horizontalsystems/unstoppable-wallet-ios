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
                .title(icon: ThemeImage.warning, title: title),
                .text(text: description),
                .buttonGroup(.init(buttons: [
                    .init(style: .yellow, title: "backup_prompt.backup_manual".localized, icon: "edit_24") {
                        isPresented = false

                        Coordinator.shared.present { _ in
                            BackupManualView(account: account).ignoresSafeArea()
                        }
                        stat(page: statPage, event: .open(page: .manualBackup))
                    },
                    .init(style: .gray, title: "backup_prompt.backup_cloud".localized, icon: "icloud_24") {
                        isPresented = false

                        Coordinator.shared.presentWalletBackup(account: account, statPage: statPage)
                    },
                    .init(style: .transparent, title: cancelText) {
                        isPresented = false
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
}
