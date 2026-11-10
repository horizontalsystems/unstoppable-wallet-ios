import Combine
import MarketKit
import SwiftUI

struct RestoreMnemonicView: View {
    @StateObject private var viewModel: RestoreMnemonicViewModel
    @Binding private var isParentPresented: Bool

    @State private var passphrase = ""
    @State private var passphraseSecureLock = true
    @State private var isMnemonicFocused = false

    @State private var restoreCoinsData: RestoreCoinsData?

    @FocusState private var focusedField: Field?
    /// the masked passphrase field is a UIKit text field that @FocusState does not track
    @State private var passphraseFocused = false

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
                        advancedToggleSection

                        if viewModel.advanced {
                            advancedContent
                        }
                    }
                    .padding(EdgeInsets(top: 24, leading: 16, bottom: 32, trailing: 16))
                    .animation(.default, value: viewModel.mnemonicCaution)
                    .animation(.default, value: isMnemonicFocused)
                    .animation(.default, value: viewModel.advanced)
                }
                .onTapGesture {
                    dismissKeyboard()
                }
            } bottomContent: {
                ThemeButton(text: "button.next".localized) {
                    dismissKeyboard()
                    viewModel.onTapProceed()
                }
                .disabled(!viewModel.buttonEnabled)
                .accessibilityIdentifier(TestTags.restoreNext)
            } keyboardContent: {
                if isMnemonicFocused {
                    mnemonicHintRow
                }
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
        .onReceive(viewModel.proceedPublisher) { name, accountType in
            handleProceed(name: name, accountType: accountType)
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(spacing: 0) {
            ListSectionHeader(text: "create_wallet.name".localized, uppercased: false)

            ThemeInput(
                buttons: [
                    .icon("swap_e", identifier: TestTags.restoreNameRandom) {
                        viewModel.refreshName()
                    },
                ]
            ) {
                InputTextView(text: $viewModel.name)
                    .autocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .name)
                    .accessibilityIdentifier(TestTags.restoreNameInput)
            }
        }
    }

    // MARK: - Mnemonic Section

    private var mnemonicSection: some View {
        MnemonicInputView(
            placeholder: "restore.mnemonic.placeholder".localized,
            value: $viewModel.input,
            invalidRanges: viewModel.invalidRanges,
            caution: viewModel.mnemonicCaution,
            cautionIdentifier: TestTags.restoreError,
            isFocused: $isMnemonicFocused,
            statPage: viewModel.advanced ? .importWalletFromKeyAdvanced : .importWalletFromKey,
            statEntity: .recoveryPhrase,
            identifier: TestTags.restorePhraseInput,
            buttonIdentifiers: .init(scan: TestTags.restorePhraseScan, paste: TestTags.restorePhrasePaste, clear: TestTags.restorePhraseClear)
        )
    }

    // MARK: - Advanced Toggle

    private var advancedToggleSection: some View {
        ListSection {
            Cell(
                middle: {
                    MultiText(title: "create_wallet.advanced_options".localized)
                },
                right: {
                    ThemeToggle(isOn: $viewModel.advanced)
                }
            )
        }
    }

    // MARK: - Advanced Content

    private var advancedContent: some View {
        VStack(spacing: 24) {
            ListSection {
                Cell(
                    middle: {
                        MultiText(subtitle: "create_wallet.word_list".localized)
                    },
                    right: {
                        ThemeText(
                            viewModel.wordListLanguage,
                            style: .subheadSB
                        ).arrow(style: .dropdown)
                    },
                    action: {
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
                    }
                )
            }

            VStack(spacing: 0) {
                ThemeInput(
                    buttons: [.secureToggle($passphraseSecureLock, identifier: TestTags.restorePassphraseEye)]
                ) {
                    InputTextView(
                        placeholder: "restore.input.passphrase".localized,
                        text: $passphrase,
                        isValidText: { PassphraseValidator.validate(text: $0) }
                    )
                    .secure($passphraseSecureLock, identifier: TestTags.restorePassphraseInput, isFocused: $passphraseFocused)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }
                .onChange(of: passphrase) { _, newValue in
                    viewModel.onChange(passphrase: newValue)
                }

                ListSectionFooter(text: "restore.wallet.passphrase_description".localized)
            }
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

    private func dismissKeyboard() {
        focusedField = nil
        isMnemonicFocused = false
        passphraseFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func handleProceed(name: String, accountType: AccountType) {
        let statPage: StatPage = viewModel.advanced ? .importWalletFromKeyAdvanced : .importWalletFromKey

        let supportedTokens = RestoreHelper.supportedTokens(accountType: accountType)
        let blockchains = Set(supportedTokens.map(\.blockchain))

        if blockchains.count == 1, let token = supportedTokens.first, token.blockchainType.restoreSettingTypes.isEmpty {
            RestoreHelper.restoreSingleBlockchain(accountName: name, accountType: accountType, token: token)
            stat(page: statPage, event: .importWallet(walletType: accountType.statDescription))
            isParentPresented = false
            return
        }

        restoreCoinsData = RestoreCoinsData(name: name, accountType: accountType)
    }
}

// MARK: - Supporting Types

extension RestoreMnemonicView {
    enum Field {
        case name
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
