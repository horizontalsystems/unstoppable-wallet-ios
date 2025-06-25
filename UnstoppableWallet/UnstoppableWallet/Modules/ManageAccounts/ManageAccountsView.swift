import SwiftUI

struct ManageAccountsView: View {
    @StateObject private var viewModel = ManageAccountsViewModelNew()
    @StateObject var createAccountViewModifierModel = TermsAcceptedViewModifierModel()
    @StateObject var restoreAccountViewModifierModel = TermsAcceptedViewModifierModel()

    @Binding private var isPresented: Bool
    private let onCreate: ((Account) -> Void)?

    @State private var watchPresented = false
    @State private var presentedAccount: Account?

    init(isPresented: Binding<Bool>? = nil, onCreate: ((Account) -> Void)? = nil) {
        _isPresented = isPresented ?? .constant(false)
        self.onCreate = onCreate
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
                        createAccountViewModifierModel.handle()
                    }) {
                        Image("plus_24").themeIcon(color: .themeJacob)
                        Text("onboarding.balance.create".localized).themeBody(color: .themeJacob)
                    }

                    ClickableRow(action: {
                        restoreAccountViewModifierModel.handle()
                    }) {
                        Image("download_24").themeIcon(color: .themeJacob)
                        Text("onboarding.balance.import".localized).themeBody(color: .themeJacob)
                    }

                    ClickableRow(action: {
                        watchPresented = true
                    }) {
                        Image("binocule_24").themeIcon(color: .themeJacob)
                        Text("onboarding.balance.watch".localized).themeBody(color: .themeJacob)
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .sheet(item: $presentedAccount, onDismiss: {
            if !viewModel.hasAccounts {
                isPresented = false
            }
        }) { account in
            ManageAccountView(account: account)
                .ignoresSafeArea()
        }
        .modifier(CreateAccountViewModifier(viewModel: createAccountViewModifierModel, onCreate: onCreate))
        .modifier(RestoreAccountViewModifier(viewModel: restoreAccountViewModifierModel, onRestore: isPresented ? { isPresented = false } : nil))
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

    @ViewBuilder private func itemView(item: ManageAccountsViewModelNew.Item, watch: Bool) -> some View {
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
                presentedAccount = item.account
            }) {
                Image(alert ? "warning_2_20" : "more_2_20").themeIcon(color: alert ? .themeLucian : .themeGray)
            }
            .buttonStyle(SecondaryCircleButtonStyle())
        }
    }

    private func alertSubtitle(item: ManageAccountsViewModelNew.Item) -> String? {
        if item.account.nonStandard {
            return "manage_accounts.migration_required".localized
        } else if !(item.account.backedUp || item.cloudBackedUp) {
            return "manage_accounts.backup_required".localized
        } else {
            return nil
        }
    }
}
