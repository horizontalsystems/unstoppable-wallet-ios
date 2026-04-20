import Combine
import MarketKit
import SwiftUI

struct RestoreMnemonicView: View {
    @StateObject private var viewModel: RestoreMnemonicViewModel
    @Binding private var isParentPresented: Bool

    @State private var passphrase = ""
    @State private var passphraseSecureLock = true
    @State private var isEnteringMnemonic = false
    @State private var mnemonicHeightTrigger = false

    @State private var restoreCoinsData: RestoreCoinsData?
    @State private var accountTypeSelectData: AccountTypeSelectData?

    @FocusState private var focusedField: Field?

    init(isParentPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: RestoreMnemonicViewModel())
        _isParentPresented = isParentPresented
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: 24) {
                        nameSection
                        mnemonicSection
                        advancedToggleButton
                    }
                    .padding(EdgeInsets(top: 24, leading: 16, bottom: 32, trailing: 16))
                    .animation(.default, value: viewModel.passphraseEnabled)
                    .animation(.default, value: viewModel.mnemonicCaution)
                    .animation(.default, value: viewModel.passphraseCaution)
                    .animation(.default, value: isEnteringMnemonic)
                    .animation(.default, value: viewModel.advanced)
                }
                .onTapGesture {
                    focusedField = nil
                }
            } bottomContent: {
                ThemeButton(text: "button.next".localized) {
                    focusedField = nil
                    viewModel.onTapProceed()
                }
                .disabled(!viewModel.buttonEnabled)
            } keyboardContent: {
                if isEnteringMnemonic {
                    mnemonicHintRow
                }
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
                    statPage: viewModel.advanced ? .importWalletFromKeyAdvanced : .importWalletFromKey,
                    onRestore: { isParentPresented = false }
                )
                .ignoresSafeArea()
            }
        }
        .onReceive(viewModel.proceedPublisher) { name, accountTypes in
            handleProceed(name: name, accountTypes: accountTypes)
        }
        .onReceive(viewModel.clearPassphrasePublisher) {
            passphrase = ""
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

    // MARK: - Mnemonic Section

    @ViewBuilder
    private var mnemonicSection: some View {
        VStack(spacing: 0) {
            MnemonicInputCellWrapper(
                statPage: viewModel.advanced ? .importWalletFromKeyAdvanced : .importWalletFromKey,
                placeholder: "restore.mnemonic.placeholder".localized,
                invalidRanges: $viewModel.invalidRanges,
                cautionType: viewModel.mnemonicCaution.caution?.type,
                replaceWordPublisher: viewModel.replaceWordPublisher,
                heightTrigger: $mnemonicHeightTrigger,
                onChangeMnemonicText: { text, cursorOffset in
                    viewModel.onChange(text: text, cursorOffset: cursorOffset)
                },
                onChangeEntering: { entering in
                    isEnteringMnemonic = entering
                }
            )

            if let caution = viewModel.mnemonicCaution.caution {
                Text(caution.text)
                    .themeCaption(color: viewModel.mnemonicCaution.color)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        if viewModel.advanced {
            ListSection {
                ClickableRow(action: {
                    Coordinator.shared.present(type: .alert) { isPresented in
                        OptionAlertView(
                            title: "create_wallet.word_list".localized,
                            viewItems: viewModel.wordListViewItems,
                            onSelect: { index in
                                viewModel.onSelectWordList(index: index)
                            },
                            isPresented: isPresented
                        )
                    }
                }) {
                    Image("globe_24").themeIcon()
                    Text("create_wallet.word_list".localized).textBody()
                    Spacer()
                    Text(viewModel.wordListLanguage).textSubhead1()
                    Image("arrow_small_down_20").themeIcon()
                }

                ListRow {
                    Image("key_phrase_24").themeIcon()
                    Toggle(isOn: Binding(
                        get: { viewModel.passphraseEnabled },
                        set: { viewModel.onTogglePassphrase(isOn: $0) }
                    )) {
                        Text("restore.passphrase".localized).themeBody()
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                }
            }

            if viewModel.passphraseEnabled {
                VStack(spacing: 0) {
                    InputTextRow {
                        InputTextView(
                            placeholder: "restore.input.passphrase".localized,
                            text: $passphrase,
                            isValidText: { PassphraseValidator.validate(text: $0) }
                        )
                        .secure($passphraseSecureLock)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .passphrase)
                    }
                    .modifier(CautionBorder(cautionState: $viewModel.passphraseCaution))
                    .modifier(CautionPrompt(cautionState: $viewModel.passphraseCaution))
                    .onChange(of: passphrase) {
                        viewModel.onChange(passphrase: $0)
                    }

                    ListSectionFooter(text: "restore.wallet.passphrase_description".localized)
                }
            }
        }
    }

    // MARK: - Advanced Toggle

    private var advancedToggleButton: some View {
        ThemeButton(text: viewModel.advanced ? "restore.hide_advanced_options".localized : "restore.show_advanced_options".localized, style: .secondary, mode: .transparent, size: .small) {
            viewModel.advanced.toggle()
        }
    }

    // MARK: - Hint Row

    @ViewBuilder private var mnemonicHintRow: some View {
        if viewModel.possibleWords.isEmpty {
            VStack {
                ThemeText("restore.suggestions".localized, style: .caption)
            }
            .frame(height: ThemeButton.Size.small.size)
            .padding(.bottom, 8)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.possibleWords, id: \.self) { word in
                        ThemeButton(text: word, style: .secondary, size: .small) {
                            viewModel.onSelect(word: word)
                        }
                    }
                }
                .padding(.bottom, 8)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Navigation

    private func handleProceed(name: String, accountTypes: [AccountType]) {
        let statPage: StatPage = viewModel.advanced ? .importWalletFromKeyAdvanced : .importWalletFromKey

        guard !accountTypes.isEmpty else { return }

        if accountTypes.count == 1, let accountType = accountTypes.first {
            let supportedTokens = RestoreSelectModule.supportedTokens(accountType: accountType)
            let blockchains = Set(supportedTokens.map(\.blockchain))

            if blockchains.count == 1, let token = supportedTokens.first, token.blockchainType.restoreSettingTypes.isEmpty {
                RestoreSelectModule.restoreSingleBlockchain(accountName: name, accountType: accountType, token: token)
                stat(page: statPage, event: .importWallet(walletType: accountType.statDescription))
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

extension RestoreMnemonicView {
    enum Field {
        case name
        case passphrase
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
