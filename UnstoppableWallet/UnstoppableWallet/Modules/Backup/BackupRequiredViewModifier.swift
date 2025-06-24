import SwiftUI

struct BackupRequiredViewModifier: ViewModifier {
    @Binding var account: Account?
    let title: String
    let description: (Account) -> String
    let cancelText: String
    let statPage: StatPage

    @State private var manualBackupAccount: Account?
    @State private var cloudBackupAccount: Account?

    func body(content: Content) -> some View {
        content
            .bottomSheet(item: $account) { account in
                BottomSheetView(
                    icon: .warning,
                    title: title,
                    items: [
                        .highlightedDescription(text: description(account)),
                    ],
                    buttons: [
                        .init(style: .yellow, title: "backup_prompt.backup_manual".localized, icon: "edit_24") {
                            self.account = nil
                            manualBackupAccount = account
                        },
                        .init(style: .gray, title: "backup_prompt.backup_cloud".localized, icon: "icloud_24") {
                            self.account = nil
                            cloudBackupAccount = account
                        },
                        .init(style: .transparent, title: cancelText) {
                            self.account = nil
                        },
                    ],
                    onDismiss: { self.account = nil }
                )
            }
            .sheet(item: $manualBackupAccount) { account in
                BackupView(account: account)
                    .ignoresSafeArea()
                    .onFirstAppear {
                        stat(page: statPage, event: .open(page: .manualBackup))
                    }
            }
            .sheet(item: $cloudBackupAccount) { account in
                ICloudBackupTermsView(account: account)
                    .ignoresSafeArea()
                    .onFirstAppear {
                        stat(page: statPage, event: .open(page: .cloudBackup))
                    }
            }
    }
}

extension BackupRequiredViewModifier {
    static func backupPromptAfterCreate(account: Binding<Account?>) -> BackupRequiredViewModifier {
        BackupRequiredViewModifier(
            account: account,
            title: "backup_prompt.backup_recovery_phrase".localized,
            description: { _ in "backup_prompt.warning".localized },
            cancelText: "backup_prompt.later".localized,
            statPage: .backupPromptAfterCreate
        )
    }

    static func backupPrompt(account: Binding<Account?>, description: @escaping (Account) -> String) -> BackupRequiredViewModifier {
        BackupRequiredViewModifier(
            account: account,
            title: "backup_prompt.backup_required".localized,
            description: description,
            cancelText: "button.cancel".localized,
            statPage: .backupRequired
        )
    }
}
