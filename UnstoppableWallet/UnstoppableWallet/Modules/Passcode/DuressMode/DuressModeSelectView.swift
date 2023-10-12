import SwiftUI

struct DuressModeSelectView: View {
    @ObservedObject var viewModel: DuressModeViewModel
    @Binding var showParentSheet: Bool

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                VStack(spacing: 0) {
                    PageDescription(text: "enable_duress_mode.select.description".localized)

                    VStack(spacing: .margin24) {
                        if !viewModel.regularAccounts.isEmpty {
                            VStack(spacing: 0) {
                                ListSectionHeader(text: "enable_duress_mode.select.wallets".localized)
                                ListSection {
                                    ForEach(viewModel.regularAccounts) { account in
                                        AccountRow(account: account, selectedAccountIds: $viewModel.selectedAccountIds)
                                    }
                                }
                            }
                        }

                        if !viewModel.watchAccounts.isEmpty {
                            VStack(spacing: 0) {
                                ListSectionHeader(text: "enable_duress_mode.select.watch_wallets".localized)
                                ListSection {
                                    ForEach(viewModel.watchAccounts) { account in
                                        AccountRow(account: account, selectedAccountIds: $viewModel.selectedAccountIds)
                                    }
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                NavigationLink(destination: {
                    CreatePasscodeModule.createDuressPasscodeView(accountIds: Array(viewModel.selectedAccountIds), showParentSheet: $showParentSheet)
                }) {
                    Text("button.next".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
        }
        .navigationTitle("enable_duress_mode.select.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.cancel".localized) {
                showParentSheet = false
            }
        }
    }

    private struct AccountRow: View {
        let account: Account
        @Binding var selectedAccountIds: Set<String>

        var body: some View {
            ClickableRow(action: {
                if selectedAccountIds.contains(account.id) {
                    selectedAccountIds.remove(account.id)
                } else {
                    selectedAccountIds.insert(account.id)
                }
            }) {
                VStack(spacing: 1) {
                    Text(account.name).themeBody()
                    Text(account.type.detailedDescription).themeSubhead2()
                }

                ZStack {
                    RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous)
                        .stroke(Color.themeGray, lineWidth: 1.5)
                        .frame(width: .margin24, height: .margin24)

                    if selectedAccountIds.contains(account.id) {
                        Image("check_2_20").themeIcon(color: .themeJacob)
                    }
                }
            }
        }
    }
}
