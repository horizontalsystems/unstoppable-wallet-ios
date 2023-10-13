import SDWebImageSwiftUI
import SwiftUI
import ThemeKit

struct BackupListView: View {
    @ObservedObject var viewModel: BackupAppViewModel
    var onDismiss: (() -> Void)?

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                VStack(spacing: .margin24) {
                    if !viewModel.accountItems.isEmpty {
                        VStack(spacing: 0) {
                            ListSectionHeader(text: "backup_app.backup_list.header.wallets".localized)

                            ListSection {
                                ForEach(viewModel.accountItems, id: \.accountId) { (item: BackupAppModule.AccountItem) in
                                    if viewModel.selected[item.id] != nil {
                                        let selected = binding(for: item.accountId)

                                        ClickableRow(action: {
                                            viewModel.toggle(item: item)
                                        }) {
                                            HStack {
                                                AccountView(item: item)

                                                Toggle(isOn: selected) {}
                                                    .labelsHidden()
                                                    .toggleStyle(CheckboxStyle())
                                            }
                                        }
                                    } else {
                                        ListRow {
                                            AccountView(item: item)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    VStack(spacing: 0) {
                        ListSectionHeader(text: "backup_app.backup_list.header.other".localized)

                        ListSection {
                            ForEach(viewModel.otherItems) { (item: BackupAppModule.Item) in
                                ListRow {
                                    VStack(spacing: 1) {
                                        HStack {
                                            Text(item.title).themeBody()

                                            if let value = item.value {
                                                Text(value).themeSubhead1(alignment: .trailing)
                                            }
                                        }

                                        if let description = item.description {
                                            Text(description).themeSubhead2()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            } bottomContent: {
                NavigationLink(
                    destination: BackupDisclaimerView(viewModel: viewModel, onDismiss: onDismiss),
                    isActive: $viewModel.disclaimerPushed
                ) {
                    Button(action: {
                        viewModel.disclaimerPushed = true
                    }) {
                        Text("button.next".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                }
            }
            .navigationTitle("backup_app.backup_list.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.cancel".localized) {
                    onDismiss?()
                }
            }
        }
    }

    private func binding(for key: String) -> Binding<Bool> {
        .init(
            get: { viewModel.selected[key, default: true] },
            set: { viewModel.selected[key] = $0 }
        )
    }
}

extension BackupListView {
    struct AccountView: View {
        var item: BackupAppModule.AccountItem

        var body: some View {
            let color: Color? = item.cautionType.map { $0 == .error ? .themeLucian : .themeJacob }

            VStack(spacing: 1) {
                Text(item.name).themeBody()

                Text(item.description)
                    .themeSubhead2(color: color ?? .themeGray)
            }
        }
    }
}
