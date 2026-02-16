import Combine
import SwiftUI

struct CloudRestoreBackupListView: View {
    @StateObject private var viewModel: CloudRestoreBackupListViewModel
    @Binding private var isPresented: Bool
    @Binding private var path: NavigationPath

    private let onSelectBackup: (BackupModule.NamedSource) -> Void

    init(isPresented: Binding<Bool>, path: Binding<NavigationPath>, onSelectBackup: @escaping (BackupModule.NamedSource) -> Void) {
        _isPresented = isPresented
        _path = path
        self.onSelectBackup = onSelectBackup

        _viewModel = StateObject(wrappedValue:
            CloudRestoreBackupListViewModel(service:
                CloudRestoreBackupService(
                    cloudAccountBackupManager: Core.shared.cloudBackupManager,
                    accountManager: Core.shared.accountManager
                )
            )
        )
    }

    var body: some View {
        Group {
            let isEmpty = viewModel.walletViewItems.isEmpty && viewModel.fullBackupViewItems.isEmpty

            if isEmpty {
                ThemeView(style: .list) {
                    PlaceholderViewNew(
                        icon: "no_internet_48", subtitle: "restore.cloud.empty".localized
                    )
                }
            } else {
                ScrollableThemeView {
                    VStack(spacing: .margin24) {
                        HStack {
                            ThemeText("restore.cloud.description".localized, style: .subhead)
                            Spacer()
                        }

                        if !viewModel.walletViewItems.notImported.isEmpty {
                            section(header: "restore.cloud.wallets".localized, items: viewModel.walletViewItems.notImported)
                        }

                        if !viewModel.walletViewItems.imported.isEmpty {
                            section(header: "restore.cloud.imported".localized, items: viewModel.walletViewItems.imported)
                        }

                        if !viewModel.fullBackupViewItems.isEmpty {
                            section(header: "restore.cloud.app_backups".localized, items: viewModel.fullBackupViewItems)
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            }
        }
        .navigationTitle("restore.cloud.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.cancel".localized) {
                    isPresented = false
                }
            }
        }
        .onReceive(viewModel.restorePublisher) { item in
            onSelectBackup(item)
        }
        .onReceive(viewModel.deleteItemCompletedPublisher) { successful in
            if successful {
                HudHelper.instance.show(banner: .deleted)
            } else {
                HudHelper.instance.show(
                    banner: .error(string: "backup.cloud.cant_delete_file".localized))
            }
        }
    }

    @ViewBuilder private func section(header: String, items: [CloudRestoreBackupListViewModel.BackupViewItem]) -> some View {
        ListSection(header: header) {
            ForEach(items, id: \.uniqueId) {
                item in row(item: item)
            }
        }
    }

    @ViewBuilder private func row(item: CloudRestoreBackupListViewModel.BackupViewItem) -> some View {
        Cell(
            middle: {
                MultiText(title: item.name, subtitle: item.description)
            },
            right: {
                Image.disclosureIcon
            },
            action: {
                viewModel.didTap(id: item.uniqueId)
            }
        )
        .contextMenu {
            Button {
                viewModel.remove(id: item.uniqueId)
            } label: {
                Label("button.delete".localized, image: "trash")
            }
        }
        .tint(.themeLeah)
    }
}
