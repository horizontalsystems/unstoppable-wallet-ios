import SwiftUI

struct BackupManagerView: View {
    @StateObject private var viewModel = BackupManagerViewModel()
    @StateObject var restoreAccountViewModifierModel = TermsAcceptedViewModifierModel()

    @State private var backupPresented = false
    @State private var unlockPresented = false

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                ListSection {
                    ClickableRow(action: {
                        restoreAccountViewModifierModel.handle()
                    }) {
                        Image("download_24").themeIcon(color: .themeJacob)
                        Text("backup_app.backup_manager.restore".localized).themeBody(color: .themeJacob)
                    }

                    ClickableRow(action: {
                        if viewModel.unlockRequired {
                            unlockPresented = true
                        } else {
                            backupPresented = true
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
        .sheet(isPresented: $backupPresented) {
            ThemeNavigationStack {
                BackupTypeView(isPresented: $backupPresented)
            }
        }
        .sheet(isPresented: $unlockPresented) {
            ThemeNavigationStack {
                ModuleUnlockView {
                    DispatchQueue.main.async {
                        backupPresented = true
                    }
                }
            }
        }
        .modifier(RestoreAccountViewModifier(viewModel: restoreAccountViewModifierModel, type: .full))
    }
}
