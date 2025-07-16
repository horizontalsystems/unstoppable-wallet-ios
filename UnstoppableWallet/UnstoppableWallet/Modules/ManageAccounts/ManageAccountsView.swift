import SwiftUI

struct ManageAccountsView: View {
    @StateObject private var viewModel = ManageAccountsViewModel()

    @Binding private var isPresented: Bool

    init(isPresented: Binding<Bool>? = nil) {
        _isPresented = isPresented ?? .constant(false)
    }

    var body: some View {
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

                ListSection {
                    ClickableRow(action: {
                        let onCreate = isPresented ? { isPresented = false } : nil
                        Coordinator.shared.presentAfterAcceptTerms { isPresented in
                            CreateAccountView(isPresented: isPresented, onCreate: onCreate)
                        } onPresent: {
                            stat(page: .manageWallets, event: .open(page: .newWallet))
                        }
                    }) {
                        Image("plus_24").themeIcon(color: .themeJacob)
                        Text("onboarding.balance.create".localized).themeBody(color: .themeJacob)
                    }

                    ClickableRow(action: {
                        let onRestore = isPresented ? { isPresented = false } : nil
                        Coordinator.shared.presentAfterAcceptTerms { isPresented in
                            RestoreTypeView(type: .wallet, onRestore: onRestore, isPresented: isPresented)
                        } onPresent: {
                            stat(page: .manageWallets, event: .open(page: .importWallet))
                        }
                    }) {
                        Image("download_24").themeIcon(color: .themeJacob)
                        Text("onboarding.balance.import".localized).themeBody(color: .themeJacob)
                    }

                    ClickableRow(action: {
                        let onWatch = isPresented ? { isPresented = false } : nil
                        Coordinator.shared.present { isPresented in
                            WatchView(isPresented: isPresented, onWatch: onWatch)
                        }
                        stat(page: .manageWallets, event: .open(page: .watchWallet))
                    }) {
                        Image("binocule_24").themeIcon(color: .themeJacob)
                        Text("onboarding.balance.watch".localized).themeBody(color: .themeJacob)
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationBarTitle("settings_manage_keys.title".localized)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isPresented {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("button.done".localized)
                    }
                }
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
