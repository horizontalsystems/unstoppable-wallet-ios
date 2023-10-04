import SwiftUI
import ThemeKit

struct BackupTypeView: View {
    @ObservedObject var viewModel: BackupAppViewModel
    @Binding var backupPresented: Bool

    @State var cloudNavigationPushed = false
    @State var localNavigationPushed = false
    @State var cloudAlertPresented = false

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                Text("backup_type.description".localized)
                    .themeSubhead2()
                    .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin12, trailing: .margin16))

                ListSection {
                    navigation(image: "icloud_24", text: "backup_type.cloud".localized, isAvailable: $viewModel.cloudAvailable, isActive: $cloudNavigationPushed) {
                        if viewModel.cloudAvailable { viewModel.destination = .cloud } else { cloudAlertPresented = true }
                    }

                    navigation(image: "file_24", text: "backup_type.file".localized, isActive: $localNavigationPushed) {
                        viewModel.destination = .local
                    }
                }
                .sheet(isPresented: $cloudAlertPresented) {
                    if #available(iOS 16, *) {
                        ViewWrapper(BottomSheetModule.cloudNotAvailableController()).presentationDetents([.medium])
                    } else {
                        ViewWrapper(BottomSheetModule.cloudNotAvailableController())
                    }
                }
            }
            .navigationBarTitle("backup_type.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.cancel".localized) {
                    backupPresented = false
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
    }

    @ViewBuilder func row(image: String, text: String) -> some View {
        HStack(spacing: .margin16) {
            Image(image).themeIcon()
            Text(text).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder func navigation(image: String, text: String, isAvailable: Binding<Bool> = .constant(true), isActive: Binding<Bool>, action: @escaping () -> Void = {}) -> some View {
        if isAvailable.wrappedValue {
            NavigationRow(
                destination: { BackupListView(viewModel: viewModel, backupPresented: $backupPresented) },
                isActive: isActive
            ) {
                row(image: image, text: text.localized)
            }
            .onChange(of: isActive.wrappedValue) { _ in action() }
        } else {
            ClickableRow(action: action) {
                row(image: image, text: text.localized)
            }
        }
    }
}
