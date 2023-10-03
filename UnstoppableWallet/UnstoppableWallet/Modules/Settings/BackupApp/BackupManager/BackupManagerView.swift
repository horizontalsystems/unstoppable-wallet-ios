import SDWebImageSwiftUI
import SwiftUI
import ThemeKit

struct BackupManagerView: View {
    @State var restorePresented: Bool = false
    @State var backupPresented: Bool = false

    var body: some View {
        ScrollableThemeView {
            ListSection {
                ClickableRow(action: {
                    restorePresented = true
                }) {
                    Image("download_24").themeIcon(color: .themeJacob)
                    Text("backup_manager.restore".localized).themeBody(color: .themeJacob)
                }
                ClickableRow(action: {
                    backupPresented = true
                }) {
                    Image("plus_24").themeIcon(color: .themeJacob)
                    Text("backup_manager.create".localized).themeBody(color: .themeJacob)
                }
            }
            .sheet(isPresented: $restorePresented) {
                InfoModule.restoreSourceInfo
            }
            .sheet(isPresented: $backupPresented) {
                ThemeNavigationView { BackupAppModule.view(backupPresented: $backupPresented) }
            }
            .navigationBarTitle("backup_manager.title".localized)
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
    }
}
