import SwiftUI

struct BackupTypeView: View {
    @StateObject private var viewModel = BackupAppViewModel()
    @Binding var isPresented: Bool

    @State var navigationPushed = false

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin12) {
                ListSection {
                    ClickableRow(action: {
                        if viewModel.cloudAvailable {
                            viewModel.destination = .cloud
                            navigationPushed = true
                        } else {
                            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                                CloudNotAvailableView(isPresented: isPresented)
                            }
                        }
                    }) {
                        row(
                            image: "icloud_24",
                            text: "backup_app.backup_type.cloud".localized,
                            description: "backup_app.backup_type.cloud.description".localized
                        )
                    }
                    .frame(minHeight: 106)
                }

                ListSection {
                    ClickableRow(action: {
                        viewModel.destination = .local
                        navigationPushed = true
                    }) {
                        row(
                            image: "file_24",
                            text: "backup_app.backup_type.file".localized,
                            description: "backup_app.backup_type.file.description".localized
                        )
                    }
                    .frame(minHeight: 106)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("backup_app.backup_type.title".localized)
        .navigationDestination(isPresented: $navigationPushed) {
            BackupListView(viewModel: viewModel, isPresented: $isPresented)
                .onFirstAppear { stat(page: .exportFull, event: .open(page: viewModel.statPage)) }
        }
        .toolbar {
            Button("button.cancel".localized) {
                isPresented = false
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
}
