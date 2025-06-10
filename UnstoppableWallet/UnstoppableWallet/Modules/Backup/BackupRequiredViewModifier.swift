import SwiftUI

struct BackupRequiredViewModifier: ViewModifier {
    @Binding var account: Account?
    let statPage: StatPage
    let description: (Account) -> String

    @State private var manualBackupAccount: Account?
    @State private var cloudBackupAccount: Account?

    func body(content: Content) -> some View {
        content
            .bottomSheet(item: $account) { account in
                BottomSheetView(
                    icon: .warning,
                    title: "backup_prompt.backup_required".localized,
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
                        .init(style: .transparent, title: "button.cancel".localized) {
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
