import SwiftUI

struct BackupManagerView: View {
    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                ListSection {
                    Cell(
                        middle: {
                            MultiText(title: "backup_app.backup_manager.restore".localized)
                        },
                        right: {
                            Image.disclosureIcon
                        },
                        action: {
                            Coordinator.shared.presentAfterAcceptTerms { isPresented in
                                FullRestoreTypeView(isPresented: isPresented)
                            } onPresent: {
                                stat(page: .backupManager, event: .open(page: .importWallet))
                            }
                        }
                    )
                    Cell(
                        middle: {
                            MultiText(title: "backup_app.backup_manager.create".localized)
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
