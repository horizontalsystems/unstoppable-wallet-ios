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
            set: {
                if !$0 {
                    restoreCoinsData = nil
                }
            }
        )) {
            if let data = restoreCoinsData {
                RestoreCoinsView(accountName: data.name, accountType: data.accountType, isParentPresented: $isParentPresented)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { accountTypeSelectData != nil },
            set: {
                if !$0 {
                    accountTypeSelectData = nil
                }
            }
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

            ThemeInput(
                buttons: [
                    .icon("swap_e", identifier: TestTags.restoreKeyNameRandom) {
                        viewModel.refreshName()
                    },
                ]
            ) {
                InputTextView(text: $viewModel.name)
                    .autocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .name)
                    .accessibilityIdentifier(TestTags.restoreKeyNameInput)
            }
        }
    }

    private var privateKeySection: some View {
        ThemeInput(
            kind: .area,
            caution: viewModel.privateKeyCaution,
            buttons: ThemeInputButton.shortcuts(
                isEmpty: privateKeyText.isEmpty,
                whenEmpty: [
                    .scan(options: [.picker], identifier: TestTags.restoreKeyScan) { text in
                        privateKeyText = text
                        stat(page: .importWalletFromKey, event: .scanQr(entity: .key))
                    },
                    .paste(identifier: TestTags.restoreKeyPaste) { string in
                        privateKeyText = string
                        stat(page: .importWalletFromKey, event: .paste(entity: .key))
                    },
                ],
                deleteIdentifier: TestTags.restoreKeyClear,
                onDelete: {
                    privateKeyText = ""
                }
            )
        ) {
            InputTextView(
                placeholder: "restore.private_key.placeholder".localized,
                multiline: true,
                text: $privateKeyText
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .key)
            .accessibilityIdentifier(TestTags.restoreKeyInput)
        }
        .onChange(of: privateKeyText) { _, newValue in
            viewModel.onChange(privateKey: newValue)
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
