import SwiftUI

struct BackupSelectContentView: View {
    @ObservedObject var viewModel: BackupViewModel
    @StateObject private var contentViewModel: BackupSelectContentViewModel
    @Binding var path: NavigationPath

    init(viewModel: BackupViewModel, path: Binding<NavigationPath>) {
        self.viewModel = viewModel
        _contentViewModel = StateObject(wrappedValue: BackupSelectContentViewModel(selectedAccountIds: viewModel.selectedAccountIds))
        _path = path
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin24) {
                        if !contentViewModel.accountItems.isEmpty {
                            walletSection(items: contentViewModel.accountItems)
                        }

                        contentSection(items: contentViewModel.contentItems)
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                Button(action: {
                    onNext()
                }) {
                    Text("button.next".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
        }
        .navigationTitle("backup_app.backup_list.title".localized)
        .toolbar {
            Button("button.cancel".localized) {
                viewModel.cancel()
            }
        }
    }

    private func walletSection(items: [BackupModule.AccountItem]) -> some View {
        ListSection(header: "backup_app.backup_list.header.wallets".localized) {
            ForEach(items, id: \.accountId) { item in
                AccountItemView(
                    item: item,
                    isSelected: contentViewModel.selectedAccountIds.contains(item.accountId),
                    onToggle: {
                        contentViewModel.toggle(accountId: $0.accountId)
                    }
                )
            }
        }
    }

    private func contentSection(items: [BackupModule.ContentItem]) -> some View {
        ListSection(header: "backup_app.backup_list.header.wallets".localized) {
            ForEach(items, id: \.id) { item in
                ContentItemView(item: item)
            }
        }
    }

    private func onNext() {
        viewModel.setSelectedAccountIds(contentViewModel.selectedAccountIds)
        path.append(BackupModule.Step.disclaimer)
    }
}

struct AccountItemView: View {
    let item: BackupModule.AccountItem
    let isSelected: Bool
    let onToggle: (BackupModule.AccountItem) -> Void

    var body: some View {
        Cell(
            middle: {
                MultiText(title: item.name, subtitle: ComponentText(text: item.description, colorStyle: item.cautionType?.colorStyle))
            },
            right: {
                Image.checkbox(active: isSelected)
            },
            action: {
                onToggle(item)
            }
        )
    }
}

struct ContentItemView: View {
    let item: BackupModule.ContentItem

    var body: some View {
        Cell(
            middle: {
                MultiText(title: item.title, subtitle: item.description)
            },
            right: {
                if let value = item.value {
                    RightTextIcon(text: ComponentText(text: value, colorStyle: .secondary))
                }
            }
        )
    }
}
