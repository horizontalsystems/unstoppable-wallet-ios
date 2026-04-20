import Combine
import MarketKit
import SwiftUI

struct RestorePrivateKeyView: View {
    @StateObject private var viewModel: RestorePrivateKeyViewModel
    @Binding private var isParentPresented: Bool

    @State private var privateKeyText = ""
    @State private var restoreCoinsData: RestoreCoinsData?
    @State private var accountTypeSelectData: AccountTypeSelectData?

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
                    .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
                    .animation(.default, value: viewModel.privateKeyCaution)
                }
            } bottomContent: {
                Button(action: {
                    viewModel.onTapProceed()
                }) {
                    Text("button.next".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
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
                AccountTypeSelectWrapper(
                    accountName: data.name,
                    accountTypes: data.accountTypes,
                    statPage: .importWalletFromKey,
                    onRestore: { isParentPresented = false }
                )
                .ignoresSafeArea()
            }
        }
        .onReceive(viewModel.proceedSubject) { name, accountTypes in
            handleProceed(name: name, accountTypes: accountTypes)
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(spacing: 0) {
            ListSectionHeader(text: "create_wallet.name".localized)

            InputTextRow {
                InputTextView(text: $viewModel.name)
                    .autocapitalization(.words)
                    .autocorrectionDisabled()
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
            .modifier(CautionBorder(cautionState: $viewModel.privateKeyCaution))
            .modifier(CautionPrompt(cautionState: $viewModel.privateKeyCaution))
        }
    }

    // MARK: - Navigation

    private func handleProceed(name: String, accountTypes: [AccountType]) {
        guard !accountTypes.isEmpty else { return }

        if accountTypes.count == 1, let accountType = accountTypes.first {
            let supportedTokens = RestoreSelectModule.supportedTokens(accountType: accountType)
            let blockchains = Set(supportedTokens.map(\.blockchain))

            if blockchains.count == 1, let token = supportedTokens.first, token.blockchainType.restoreSettingTypes.isEmpty {
                RestoreSelectModule.restoreSingleBlockchain(accountName: name, accountType: accountType, token: token)
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

// MARK: - AccountTypeSelectWrapper

private struct AccountTypeSelectWrapper: UIViewControllerRepresentable {
    let accountName: String
    let accountTypes: [AccountType]
    let statPage: StatPage
    let onRestore: () -> Void

    func makeUIViewController(context _: Context) -> UIViewController {
        let viewModel = AccountTypeSelectViewModel(accountName: accountName, accountTypes: accountTypes)
        return AccountTypeSelectViewController(
            viewModel: viewModel,
            accountName: accountName,
            statPage: statPage,
            showCloseButton: false,
            onRestore: onRestore
        )
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

// MARK: - Supporting Types

extension RestorePrivateKeyView {
    struct RestoreCoinsData {
        let name: String
        let accountType: AccountType
    }

    struct AccountTypeSelectData {
        let name: String
        let accountTypes: [AccountType]
    }
}
