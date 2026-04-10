import Combine
import SwiftUI

struct RestoreBackupListView: View {
    @StateObject private var viewModel = RestoreBackupListViewModel()
    @Binding var isParentPresented: Bool
    var showClose = false

    @State private var filePickerPresented = false

    @State private var source: BackupModule.NamedSource?
    @State private var passphrasePresented = false

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
        .navigationDestination(isPresented: $passphrasePresented) {
            if let source {
                RestorePassphraseView(item: source, isParentPresented: $isParentPresented)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    filePickerPresented = true
                }) {
                    Image("arrow_in")
                }
            }

            if showClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isParentPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
        .fileImporter(isPresented: $filePickerPresented, allowedContentTypes: [.json]) { result in
            if case let .success(url) = result {
                do {
                    source = try RestoreFileHelper.parse(url: url, destination: .files)
                    passphrasePresented = true
                } catch {
                    HudHelper.instance.show(banner: .error(string: "alert.cant_recognize".localized))
                }
            }
        }
        .onReceive(viewModel.restorePublisher) { source in
            self.source = source
            passphrasePresented = true
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

    @ViewBuilder private func section(header: String, items: [RestoreBackupListViewModel.BackupViewItem]) -> some View {
        ListSection(header: header) {
            ForEach(items, id: \.uniqueId) {
                item in row(item: item)
            }
        }
    }

    @ViewBuilder private func row(item: RestoreBackupListViewModel.BackupViewItem) -> some View {
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
