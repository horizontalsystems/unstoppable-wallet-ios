import SwiftUI

struct BackupManagerView: View {
    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                ListSection {
                    Cell(
                        left: {
                            ThemeImage("arrow_in", size: 24)
                        },
                        middle: {
                            MultiText(
                                title: "backup_app.backup_manager.restore".localized,
                                subtitle: "backup_app.backup_manager.restore.description".localized
                            )
                        },
                        right: {
                            Image.disclosureIcon
                        },
                        action: {
                            Coordinator.shared.presentAfterAcceptTerms { isPresented in
                                ThemeNavigationStack {
                                    RestoreBackupListView(isParentPresented: isPresented, showClose: true)
                                }
                            } onPresent: {
                                stat(page: .backupManager, event: .open(page: .importWallet))
                            }
                        }
                    )
                    Cell(
                        left: {
                            ThemeImage("list", size: 24)
                        },
                        middle: {
                            MultiText(
                                title: "backup_app.backup_manager.create".localized,
                                subtitle: "backup_app.backup_manager.create.description".localized
                            )
                        },
                        right: {
                            Image.disclosureIcon
                        },
                        action: {
                            Coordinator.shared.presentAfterUnlock { isPresented in
                                BackupModule.backupApp(isPresented: isPresented)
                            }
                        }
                    )
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("backup_app.backup_manager.title".localized)
    }
}
