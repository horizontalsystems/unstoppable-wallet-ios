import SwiftUI
import ThemeKit

struct BackupTypeView: View {
    @ObservedObject var viewModel: BackupAppViewModel
    var onDismiss: (() -> Void)?

    @State var cloudNavigationPushed = false
    @State var localNavigationPushed = false
    @State var cloudAlertPresented = false

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin12) {
                ListSection {
                    navigation(
                        image: "icloud_24",
                        text: "backup_app.backup_type.cloud".localized,
                        description: "backup_app.backup_type.cloud.description".localized,
                        isAvailable: $viewModel.cloudAvailable,
                        isActive: $cloudNavigationPushed
                    ) {
                        if viewModel.cloudAvailable { viewModel.destination = .cloud } else { cloudAlertPresented = true }
                    }
                    .frame(minHeight: 106)
                }
                .sheet(isPresented: $cloudAlertPresented) {
                    if #available(iOS 16, *) {
                        ViewWrapper(BottomSheetModule.cloudNotAvailableController()).presentationDetents([.medium])
                    } else {
                        ViewWrapper(BottomSheetModule.cloudNotAvailableController())
                    }
                }

                ListSection {
                    navigation(
                        image: "file_24",
                        text: "backup_app.backup_type.file".localized,
                        description: "backup_app.backup_type.file.description".localized,
                        isActive: $localNavigationPushed
                    ) {
                        viewModel.destination = .local
                    }
                    .frame(minHeight: 106)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("backup_app.backup_type.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.cancel".localized) {
                onDismiss?()
            }
        }
    }

    @ViewBuilder func row(image: String, text: String, description: String) -> some View {
        HStack(spacing: .margin16) {
            Image(image).themeIcon()
            VStack(spacing: .margin4) {
                Text(text).themeBody()
                Text(description).themeSubhead2()
            }
        }
        .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin12, trailing: 0))
    }

    @ViewBuilder func navigation(image: String, text: String, description: String, isAvailable: Binding<Bool> = .constant(true), isActive: Binding<Bool>, action: @escaping () -> Void = {}) -> some View {
        if isAvailable.wrappedValue {
            NavigationRow(
                destination: { BackupListView(viewModel: viewModel, onDismiss: onDismiss) },
                isActive: isActive
            ) {
                row(image: image, text: text.localized, description: description)
            }
            .onChange(of: isActive.wrappedValue) { _ in action() }
        } else {
            ClickableRow(action: action) {
                row(image: image, text: text.localized, description: description)
            }
        }
    }
}
