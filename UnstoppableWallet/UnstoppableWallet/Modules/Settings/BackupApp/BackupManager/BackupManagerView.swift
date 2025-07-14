import SwiftUI

struct BackupManagerView: View {
    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                ListSection {
                    ClickableRow(action: {
                        Coordinator.shared.presentAfterAcceptTerms { isPresented in
                            RestoreTypeView(type: .full, isPresented: isPresented)
                        } onPresent: {
                            stat(page: .backupManager, event: .open(page: .importWallet))
                        }
                    }) {
                        Image("download_24").themeIcon(color: .themeJacob)
                        Text("backup_app.backup_manager.restore".localized).themeBody(color: .themeJacob)
                    }

                    ClickableRow(action: {
                        Coordinator.shared.presentAfterUnlock { isPresented in
                            ThemeNavigationStack {
                                BackupTypeView(isPresented: isPresented)
                            }
                        }
                    }) {
                        Image("plus_24").themeIcon(color: .themeJacob)
                        Text("backup_app.backup_manager.create".localized).themeBody(color: .themeJacob)
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("backup_app.backup_manager.title".localized)
    }
}
