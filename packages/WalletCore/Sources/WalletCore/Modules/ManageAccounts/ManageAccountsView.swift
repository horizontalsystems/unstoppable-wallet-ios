import SwiftUI

struct ManageAccountsView: View {
    @StateObject private var viewModel = ManageAccountsViewModel()
    var parentPresented: Binding<Bool>?

    var body: some View {
        ThemeNavigationStack {
            Group {
                if !viewModel.hasAccounts {
                    ThemeView(style: .list) {
                        PlaceholderViewNew(icon: "wallet_remove", subtitle: "manage_wallets.empty".localized)
                    }
                } else {
                    ThemeView(style: .list) {
                        if viewModel.sections.isEmpty {
                            PlaceholderViewNew(icon: "warning_filled", subtitle: "manage_accounts.not_found".localized)
                        } else {
                            ThemeList(bottomSpacing: .margin16) {
                                ForEach(viewModel.sections) { section in
                                    Section {
                                        ListForEach(section.items) { item in
                                            itemView(item: item, index: rowIndex(of: item, in: section))
                                        }
                                    } header: {
                                        ThemeListSectionHeader(text: section.title)
                                    }
                                }
                            }
                        }
                    }
                    .searchBar(text: $viewModel.filter, prompt: "placeholder.search".localized)
                }
            }
            .navigationBarTitle("settings_manage_keys.title".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // A toolbar Menu does not take .glassProminent on iOS 26, so a styled Button draws
                    // the control and an invisible native Menu on top of it takes the taps.
                    Button(action: {}) {
                        Image("wallet_add")
                    }
                    .modifier(ConfirmationButtonStyle())
                    .accessibilityHidden(true)
                    .overlay {
                        Menu {
                            ForEach(AddWalletOption.allCases, id: \.self) { option in
                                menuButton(option: option)
                            }
                        } label: {
                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("add_wallet.title".localized)
                        .accessibilityIdentifier(TestTags.accountAdd)
                    }
                }

                if let parentPresented {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            parentPresented.wrappedValue = false
                        }) {
                            Image("close")
                        }
                    }
                }
            }
        }
    }

    private func menuButton(option: AddWalletOption) -> some View {
        Button(option.label) {
            option.perform(parentPresented: parentPresented)
        }
        .accessibilityIdentifier(option.accessibilityIdentifier)
    }

    private func itemView(item: ManageAccountsViewModel.Item, index: Int) -> some View {
        Cell(
            left: {
                CheckBoxView(checked: item.isActive)
            },
            middle: {
                let subtitle = alertSubtitle(item: item) ?? item.account.type.detailedDescription

                MultiText(title: item.account.name, subtitle: subtitle)
            },
            right: {
                let alert = item.account.nonStandard || item.account.nonRecommended || !item.account.backedUp

                IconButton(icon: alert ? "warning" : "more", iconColorStyle: alert ? .red : nil, style: .secondary, size: .small) {
                    Coordinator.shared.present { isPresented in
                        ManageAccountView(account: item.account, isPresented: isPresented)
                    } onDismiss: {
                        if !viewModel.hasAccounts {
                            parentPresented?.wrappedValue = false
                        }
                    }
                }
                .accessibilityIdentifier(TestTags.accountOptions(index))
            },
            action: {
                viewModel.set(activeAccountId: item.account.id)
                parentPresented?.wrappedValue = false
            }
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(TestTags.accountRow(index))
    }

    private func rowIndex(of item: ManageAccountsViewModel.Item, in section: ManageAccountsViewModel.Section) -> Int {
        let offset = viewModel.sections
            .prefix { $0.id != section.id }
            .reduce(0) { $0 + $1.items.count }

        return offset + (section.items.firstIndex(of: item) ?? 0)
    }

    private func alertSubtitle(item: ManageAccountsViewModel.Item) -> CustomStringConvertible? {
        if item.account.nonStandard {
            return ComponentText(text: "manage_accounts.migration_required".localized, colorStyle: .red)
        } else if !(item.account.backedUp || item.cloudBackedUp) {
            return ComponentText(text: "manage_accounts.backup_required".localized, colorStyle: .red)
        } else {
            return nil
        }
    }
}

extension ManageAccountsView {
    enum AddWalletOption: CaseIterable {
        case newWallet
        case existingWallet

        var label: String {
            switch self {
            case .newWallet: return "add_wallet.new_wallet".localized
            case .existingWallet: return "add_wallet.existing_wallet".localized
            }
        }

        var accessibilityIdentifier: String {
            switch self {
            case .newWallet: return TestTags.accountAddNewWallet
            case .existingWallet: return TestTags.accountAddExistingWallet
            }
        }

        func perform(parentPresented: Binding<Bool>?) {
            Coordinator.shared.present { ownPresented in
                ThemeNavigationStack {
                    destination(isPresented: ownPresented, parentPresented: parentPresented)
                }
            }
        }

        @ViewBuilder private func destination(isPresented: Binding<Bool>, parentPresented: Binding<Bool>?) -> some View {
            switch self {
            case .newWallet: NewWalletTypeView(isPresented: isPresented, parentPresented: parentPresented, showClose: true)
            case .existingWallet: RestoreTypeView(isPresented: isPresented, parentPresented: parentPresented, showClose: true)
            }
        }
    }
}
