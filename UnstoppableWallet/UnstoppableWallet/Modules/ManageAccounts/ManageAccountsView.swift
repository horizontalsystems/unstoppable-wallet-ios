import SwiftUI

struct ManageAccountsView: View {
    @StateObject private var viewModel = ManageAccountsViewModel()
    @Binding var isPresented: Bool

    @State private var addWalletPresented = false

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
                    Button(action: {
                        Coordinator.shared.performAfterAcceptTerms {
                            if isPresented {
                                addWalletPresented = true
                            } else {
                                Coordinator.shared.present { isPresented in
                                    ThemeNavigationStack {
                                        AddWalletView(isParentPresented: isPresented, showClose: true)
                                    }
                                }
                            }
                        }
                    }) {
                        Image("wallet_add")
                    }
                }

                if isPresented {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            isPresented = false
                        }) {
                            Image("close")
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $addWalletPresented) {
                AddWalletView(isParentPresented: $isPresented)
            }
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
                            isPresented = false
                        }
                    }
                }) {
                    ThemeImage(alert ? "warning" : "more", size: .iconSize24, colorStyle: alert ? .red : .primary)
                }
                .buttonStyle(SecondaryCircleButtonStyle())
            },
            action: {
                viewModel.set(activeAccountId: item.account.id)

                if isPresented {
                    isPresented = false
                }
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
