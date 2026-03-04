import SwiftUI

struct BackupSelectDestinationView: View {
    @ObservedObject var viewModel: BackupViewModel
    @Binding var path: NavigationPath

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin12) {
                ListSection {
                    ForEach(BackupModule.Destination.allCases) { destination in
                        row(destination: destination)
                    }
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
    private func row(destination: BackupModule.Destination) -> some View {
        Cell(
            left: {
                Image(destination.icon).icon(size: 24)
            },
            middle: {
                MultiText(title: destination.title, subtitle: destination.description)
            },
            right: {
                Image.disclosureIcon
            },
            action: {
                selectDestination(destination)
            }
        )
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
            path.append(BackupModule.Step.form)
        case .app:
            path.append(BackupModule.Step.selectContent)
        }
    }
}

extension BackupModule.Destination {
    var icon: String {
        switch self {
        case .cloud:
            return "cloud"
        case .files:
            return "file"
        }
    }

    var title: String {
        switch self {
        case .cloud:
            return "backup_app.backup_type.cloud".localized
        case .files:
            return "backup_app.backup_type.file".localized
        }
    }

    var description: String {
        switch self {
        case .cloud:
            return "backup_app.backup_type.cloud.description".localized
        case .files:
            return "backup_app.backup_type.file.description".localized
        }
    }
}
