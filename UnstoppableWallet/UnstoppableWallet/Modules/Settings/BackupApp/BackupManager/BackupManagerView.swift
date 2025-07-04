import SwiftUI

struct BackupManagerView: View {
    @StateObject var restoreAccountViewModifierModel = TermsAcceptedViewModifierModel()
    @StateObject var unlockViewModifierModel = UnlockViewModifierModel()

    @State private var backupPresented = false

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
                        unlockViewModifierModel.handle {
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
        .modifier(RestoreAccountViewModifier(viewModel: restoreAccountViewModifierModel, type: .full))
        .modifier(UnlockViewModifier(viewModel: unlockViewModifierModel))
    }
}
