import Combine
import MarketKit
import SwiftUI

struct RestorePrivateKeyView: View {
    @StateObject private var viewModel: RestorePrivateKeyViewModel
    @Binding private var isParentPresented: Bool

    @State private var privateKeyText = ""
    @State private var restoreCoinsData: RestoreCoinsData?
    @State private var accountTypeSelectData: AccountTypeSelectData?

    @FocusState private var focusedField: Field?

    init(isParentPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: RestorePrivateKeyViewModel())
        _isParentPresented = isParentPresented
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: 24) {
                        nameSection
                        privateKeySection
                    }
                    .padding(EdgeInsets(top: 24, leading: 16, bottom: 32, trailing: 16))
                    .animation(.default, value: viewModel.privateKeyCaution)
                }
                .onTapGesture {
                    focusedField = nil
                }
            } bottomContent: {
                ThemeButton(text: "button.next".localized) {
                    viewModel.onTapProceed()
                }
                .disabled(!viewModel.buttonEnabled)
            }
        }
        .navigationTitle("restore.title".localized)
        .navigationDestination(isPresented: Binding(
            get: { restoreCoinsData != nil },
            set: { if !$0 { restoreCoinsData = nil } }
        )) {
            if let data = restoreCoinsData {
                RestoreCoinsView(accountName: data.name, accountType: data.accountType, isParentPresented: $isParentPresented)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { accountTypeSelectData != nil },
            set: { if !$0 { accountTypeSelectData = nil } }
        )) {
            if let data = accountTypeSelectData {
                AccountTypeSelectView(
                    accountName: data.name,
                    accountTypes: data.accountTypes,
                    isParentPresented: $isParentPresented
                )
            }
        }
        .onReceive(viewModel.proceedSubject) { name, accountTypes in
            handleProceed(name: name, accountTypes: accountTypes)
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(spacing: 0) {
            ListSectionHeader(text: "create_wallet.name".localized, uppercased: false)

            InputTextRow {
                ShortcutButtonsView(
                    content: {
                        InputTextView(text: $viewModel.name)
                            .autocapitalization(.words)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .name)
                    },
                    showDelete: .init(get: { false }, set: { _ in }),
                    items: [.icon("swap_e")],
                    onTap: { _ in
                        viewModel.refreshName()
                    },
                    onTapDelete: {}
                )
                .padding(.vertical, -5) // TODO: remove this
            }
        }
    }

    @ViewBuilder
    private var privateKeySection: some View {
        VStack(spacing: 0) {
            LargeTextField(
                placeholder: "restore.private_key.placeholder".localized,
                text: $privateKeyText,
                statPage: .importWalletFromKey,
                statEntity: .key
            )
            .onChange(of: privateKeyText) {
                viewModel.onChange(privateKey: $0)
            }
            .focused($focusedField, equals: .key)
            .modifier(CautionBorder(cautionState: $viewModel.privateKeyCaution))
            .modifier(CautionPrompt(cautionState: $viewModel.privateKeyCaution))
        }
    }

    // MARK: - Navigation

    private func handleProceed(name: String, accountTypes: [AccountType]) {
        guard !accountTypes.isEmpty else { return }

        if accountTypes.count == 1, let accountType = accountTypes.first {
            let supportedTokens = RestoreHelper.supportedTokens(accountType: accountType)
            let blockchains = Set(supportedTokens.map(\.blockchain))

            if blockchains.count == 1, let token = supportedTokens.first, token.blockchainType.restoreSettingTypes.isEmpty {
                RestoreHelper.restoreSingleBlockchain(accountName: name, accountType: accountType, token: token)
                stat(page: .importWalletFromKey, event: .importWallet(walletType: accountType.statDescription))
                isParentPresented = false
                return
            }

            restoreCoinsData = RestoreCoinsData(name: name, accountType: accountType)
            return
        }

        accountTypeSelectData = AccountTypeSelectData(name: name, accountTypes: accountTypes)
    }
}

// MARK: - Supporting Types

extension RestorePrivateKeyView {
    enum Field {
        case name
        case key
    }

    struct RestoreCoinsData {
        let name: String
        let accountType: AccountType
    }

    struct AccountTypeSelectData {
        let name: String
        let accountTypes: [AccountType]
    }
}
