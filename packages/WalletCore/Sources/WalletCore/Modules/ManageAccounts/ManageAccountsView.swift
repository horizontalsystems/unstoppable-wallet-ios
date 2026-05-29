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
                                            itemView(item: item)
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
                    Menu {
                        ForEach(AddWalletOption.allCases, id: \.self) { option in
                            menuButton(option: option)
                        }
                    } label: {
                        Image("wallet_add")
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

    @ViewBuilder private func menuButton(option: AddWalletOption) -> some View {
        Button(option.label) {
            option.perform(parentPresented: parentPresented)
        }
    }

    @ViewBuilder private func itemView(item: ManageAccountsViewModel.Item) -> some View {
        Cell(
            left: {
                Image.checkbox(active: item.isActive)
            },
            middle: {
                let subtitle = alertSubtitle(item: item) ?? item.account.type.detailedDescription

                MultiText(title: item.account.name, subtitle: subtitle)
            },
            right: {
                let alert = item.account.nonStandard || item.account.nonRecommended || !item.account.backedUp

                Button(action: {
                    Coordinator.shared.present { isPresented in
                        ManageAccountView(account: item.account, isPresented: isPresented)
                    } onDismiss: {
                        if !viewModel.hasAccounts {
                            parentPresented?.wrappedValue = false
                        }
                    }
                }) {
                    ThemeImage(alert ? "warning" : "more", size: .iconSize24, colorStyle: alert ? .red : .primary)
                }
                .buttonStyle(SecondaryCircleButtonStyle())
            },
            action: {
                viewModel.set(activeAccountId: item.account.id)
                parentPresented?.wrappedValue = false
            }
        )
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
        case watchWallet

        var label: String {
            switch self {
            case .newWallet: return "add_wallet.new_wallet".localized
            case .existingWallet: return "add_wallet.existing_wallet".localized
            case .watchWallet: return "add_wallet.watch_wallet".localized
            }
        }

        func perform(parentPresented: Binding<Bool>?) {
            Coordinator.shared.performAfterAcceptTerms {
                if case .watchWallet = self {
                    stat(page: .addWallet, event: .open(page: .watchWallet))
                }

                Coordinator.shared.present { ownPresented in
                    ThemeNavigationStack {
                        destination(isPresented: ownPresented, parentPresented: parentPresented)
                    }
                }
            }
        }

        @ViewBuilder private func destination(isPresented: Binding<Bool>, parentPresented: Binding<Bool>?) -> some View {
            switch self {
            case .newWallet: NewWalletView(isPresented: isPresented, parentPresented: parentPresented, showClose: true)
            case .existingWallet: RestoreTypeView(isPresented: isPresented, parentPresented: parentPresented, showClose: true)
            case .watchWallet: WatchView(isPresented: isPresented, parentPresented: parentPresented, showClose: true)
            }
        }
    }
}
