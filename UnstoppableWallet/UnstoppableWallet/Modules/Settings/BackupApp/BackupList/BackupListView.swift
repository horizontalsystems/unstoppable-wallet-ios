import SDWebImageSwiftUI
import SwiftUI
import ThemeKit

struct BackupListView: View {
    @ObservedObject var viewModel: BackupAppViewModel
    @Binding var backupPresented: Bool

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                VStack(spacing: .margin24) {
                    VStack(spacing: 0) {
                        ListSectionHeader(text: "backup_list.header.wallets".localized)

                        ListSection {
                            ForEach(viewModel.accountItems, id: \.accountId) { (item: BackupAppViewModel.AccountItem) in
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

                    VStack(spacing: 0) {
                        ListSectionHeader(text: "backup_list.header.other".localized)

                        ListSection {
                            ForEach(viewModel.otherItems) { (item: BackupAppViewModel.Item) in
                                ListRow {
                                    VStack(spacing: 1) {
                                        Text(item.title).themeBody()

                                        Text(item.description).themeSubhead2()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            } bottomContent: {
                NavigationLink(
                    destination: BackupDisclaimerView(viewModel: viewModel, backupPresented: $backupPresented),
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
            .navigationTitle("backup_list.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.cancel".localized) {
                    backupPresented = false
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
        var item: BackupAppViewModel.AccountItem

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
