import SwiftUI

struct ManageAccountsView: View {
    @StateObject private var viewModel = ManageAccountsViewModel()
    @Binding var isPresented: Bool

    @State private var addWalletPresented = false

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                VStack(spacing: .margin24) {
                    if !viewModel.regularItems.isEmpty {
                        ListSection {
                            ForEach(viewModel.regularItems, id: \.account) { item in
                                itemView(item: item, watch: false)
                            }
                        }
                    }

                    if !viewModel.watchItems.isEmpty {
                        ListSection {
                            ForEach(viewModel.watchItems, id: \.account) { item in
                                itemView(item: item, watch: true)
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationBarTitle("settings_manage_keys.title".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Coordinator.shared.performAfterAcceptTerms {
                            addWalletPresented = true
                        }
                    }) {
                        Image("wallet_add")
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    if isPresented {
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

    @ViewBuilder private func itemView(item: ManageAccountsViewModel.Item, watch: Bool) -> some View {
        ClickableRow(action: {
            viewModel.set(activeAccountId: item.account.id)

            if isPresented {
                isPresented = false
            }
        }) {
            Image(item.isActive ? "circle_radioon_24" : "circle_radiooff_24")

            VStack(spacing: 1) {
                let alertSubtitle = alertSubtitle(item: item)

                Text(item.account.name).themeBody()
                Text(alertSubtitle ?? item.account.type.detailedDescription).themeSubhead2(color: alertSubtitle != nil ? .themeLucian : .themeGray)
            }

            if watch {
                Image("binocule_20")
            }

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
                Image(alert ? "warning_2_20" : "more_2_20").themeIcon(color: alert ? .themeLucian : .themeGray)
            }
            .buttonStyle(SecondaryCircleButtonStyle())
        }
    }

    private func alertSubtitle(item: ManageAccountsViewModel.Item) -> String? {
        if item.account.nonStandard {
            return "manage_accounts.migration_required".localized
        } else if !(item.account.backedUp || item.cloudBackedUp) {
            return "manage_accounts.backup_required".localized
        } else {
            return nil
        }
    }
}
