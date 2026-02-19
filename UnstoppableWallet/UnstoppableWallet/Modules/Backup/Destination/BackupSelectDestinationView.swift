import SwiftUI

struct BackupSelectDestinationView: View {
    @ObservedObject var viewModel: BackupViewModel
    @Binding var path: NavigationPath

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin12) {
                ListSection {
                    ClickableRow(action: {
                        selectDestination(.cloud)
                    }) {
                        row(
                            image: "icloud_24",
                            title: "backup_app.backup_type.cloud".localized,
                            description: "backup_app.backup_type.cloud.description".localized
                        )
                    }
                    .frame(minHeight: 106)
                }

                ListSection {
                    ClickableRow(action: {
                        selectDestination(.files)
                    }) {
                        row(
                            image: "file_24",
                            title: "backup_app.backup_type.file".localized,
                            description: "backup_app.backup_type.file.description".localized
                        )
                    }
                    .frame(minHeight: 106)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("backup_app.backup_type.title".localized)
        .toolbar {
            Button("button.cancel".localized) {
                viewModel.cancel()
            }
        }
    }

    @ViewBuilder
    private func row(image: String, title: String, description: String) -> some View {
        HStack(spacing: .margin16) {
            Image(image).themeIcon()
            VStack(spacing: .margin4) {
                Text(title).themeBody()
                Text(description).themeSubhead2()
            }
        }
        .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin12, trailing: 0))
    }

    private func selectDestination(_ destination: BackupModule.Destination) {
        if destination == .cloud {
            guard viewModel.cloudAvailable else {
                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                    CloudNotAvailableView(isPresented: isPresented)
                }
                return
            }
        }

        viewModel.setDestination(destination)

        switch viewModel.type {
        case .wallet:
            path.append(BackupModule.Step.disclaimer)
        case .app:
            path.append(BackupModule.Step.selectContent)
        }
    }
}
