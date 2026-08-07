import SwiftUI

struct BackupPromptView: View {
    let account: Account

    @Binding var isPresented: Bool

    var body: some View {
        BottomSheetView(
            items: [
                .title(icon: ThemeImage.warning, title: "backup_prompt.title".localized),
                .text(text: "backup_prompt.description".localized),
                .customList(views: [
                    AnyView(
                        Cell(
                            left: {
                                Image("edit_24").themeIcon(color: .themeJacob)
                            },
                            middle: {
                                MultiText(title: "backup_prompt.backup_manual".localized, subtitle: "backup_prompt.backup_manual.description".localized)
                            },
                            right: {
                                Image.disclosureIcon
                            },
                            action: {
                                isPresented = false

                                Coordinator.shared.performAfterUnlock {
                                    Coordinator.shared.present { _ in
                                        BackupManualView(account: account).ignoresSafeArea()
                                    }
                                    stat(page: .backupRequired, event: .open(page: .manualBackup))
                                }
                            }
                        )
                    ),
                    AnyView(HorizontalDivider()),
                    AnyView(
                        Cell(
                            left: {
                                Image("icloud_24").themeIcon(color: .themeJacob)
                            },
                            middle: {
                                MultiText(title: "backup_prompt.backup_cloud".localized, subtitle: "backup_prompt.backup_cloud.description".localized)
                            },
                            right: {
                                Image.disclosureIcon
                            },
                            action: {
                                isPresented = false

                                Coordinator.shared.presentWalletBackup(account: account, statPage: .backupRequired)
                            }
                        )
                    ),
                ]),
                .buttonGroup(.init(buttons: [
                    .init(style: .gray, title: "backup_prompt.remind_later".localized) {
                        isPresented = false
                    },
                ])),
            ]
        )
    }
}
