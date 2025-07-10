import HdWalletKit
import SwiftUI

struct CreateAccountView: View {
    @StateObject private var viewModel = CreateAccountViewModelNew()

    @Binding var isPresented: Bool
    var onCreate: (() -> Void)? = nil

    @State private var wordCountPresented = false
    @State private var secureLock = true
    @State private var passphraseCaution: CautionState = .none
    @State private var passphraseConfirmationCaution: CautionState = .none

    @FocusState private var focusedField: Field?

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
                    ScrollView {
                        VStack(spacing: .margin24) {
                            VStack(spacing: 0) {
                                ListSectionHeader(text: "create_wallet.name".localized)

                                InputTextRow {
                                    InputTextView(
                                        placeholder: viewModel.defaultAccountName,
                                        text: $viewModel.name
                                    )
                                    .autocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .name)
                                }
                            }

                            ListSection {
                                ListRow {
                                    Image("settings_2_24").themeIcon()
                                    Toggle(isOn: $viewModel.advanced) {
                                        Text("create_wallet.advanced".localized).themeBody()
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                                }
                            }

                            if viewModel.advanced {
                                ListSection {
                                    ClickableRow(spacing: .margin8, action: {
                                        wordCountPresented = true
                                    }) {
                                        HStack(spacing: .margin16) {
                                            Image("key_24")
                                            Text("create_wallet.phrase_count".localized).textBody()
                                        }

                                        Spacer()

                                        Text("create_wallet.n_words".localized("\(viewModel.wordCount.rawValue)")).textSubhead1()
                                        Image("arrow_small_down_20").themeIcon()
                                    }
                                }
                                .alert(
                                    isPresented: $wordCountPresented,
                                    title: "create_wallet.phrase_count".localized,
                                    viewItems: Mnemonic.WordCount.allCases.map {
                                        .init(text: title(wordCount: $0), selected: $0 == viewModel.wordCount)
                                    },
                                    onTap: { index in
                                        guard let index else {
                                            return
                                        }
                                        viewModel.wordCount = Mnemonic.WordCount.allCases[index]
                                    }
                                )

                                ListSection {
                                    ListRow {
                                        Image("key_phrase_24").themeIcon()
                                        Toggle(isOn: $viewModel.passphraseEnabled) {
                                            Text("create_wallet.passphrase".localized).themeBody()
                                        }
                                        .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                                    }
                                }

                                if viewModel.passphraseEnabled {
                                    VStack(spacing: 0) {
                                        VStack(spacing: .margin16) {
                                            InputTextRow {
                                                InputTextView(
                                                    placeholder: "create_wallet.input.passphrase".localized,
                                                    text: $viewModel.passphrase,
                                                    isValidText: { text in PassphraseValidator.validate(text: text) }
                                                )
                                                .secure($secureLock)
                                                .autocapitalization(.none)
                                                .autocorrectionDisabled()
                                                .focused($focusedField, equals: .passphrase)
                                            }
                                            .modifier(CautionBorder(cautionState: $passphraseCaution))
                                            .modifier(CautionPrompt(cautionState: $passphraseCaution))

                                            InputTextRow {
                                                InputTextView(
                                                    placeholder: "create_wallet.input.confirm".localized,
                                                    text: $viewModel.passphraseConfirmation,
                                                    isValidText: { text in PassphraseValidator.validate(text: text) }
                                                )
                                                .secure($secureLock)
                                                .autocapitalization(.none)
                                                .autocorrectionDisabled()
                                                .focused($focusedField, equals: .passphraseConfirmation)
                                            }
                                            .modifier(CautionBorder(cautionState: $passphraseConfirmationCaution))
                                            .modifier(CautionPrompt(cautionState: $passphraseConfirmationCaution))
                                        }
                                        .animation(.default, value: secureLock)

                                        ListSectionFooter(text: "create_wallet.passphrase_description".localized)
                                    }
                                }
                            }
                        }
                        .animation(.default, value: viewModel.advanced)
                        .animation(.default, value: viewModel.passphraseEnabled)
                        .animation(.default, value: viewModel.wordCount)
                        .animation(.default, value: passphraseCaution)
                        .animation(.default, value: passphraseConfirmationCaution)
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                    .onTapGesture {
                        focusedField = nil
                    }
                } bottomContent: {
                    VStack(spacing: .margin16) {
                        Button(action: {
                            createAccount()
                        }) {
                            Text("create_wallet.create".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .yellow))
                    }
                }
            }
            .onChange(of: viewModel.passphrase) { _ in clearCautions() }
            .onChange(of: viewModel.passphraseConfirmation) { _ in clearCautions() }
            .navigationTitle("create_wallet.title".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("create_wallet.create".localized) {
                        createAccount()
                    }
                }
            }
        }
    }

    private func title(wordCount: Mnemonic.WordCount) -> String {
        switch wordCount {
        case .twelve: return "create_wallet.12_words".localized
        default: return "create_wallet.n_words".localized("\(wordCount.rawValue)")
        }
    }

    private func clearCautions() {
        passphraseCaution = .none
        passphraseConfirmationCaution = .none
    }

    private func createAccount() {
        focusedField = nil

        do {
            let account = try viewModel.createAccount()

            HudHelper.instance.show(banner: .created)

            if let onCreate {
                onCreate()
            } else {
                isPresented = false
            }

            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                BackupRequiredView.afterCreate(account: account, isPresented: isPresented)
            }
        } catch {
            if case CreateAccountViewModelNew.CreateError.emptyPassphrase = error {
                passphraseCaution = .caution(Caution(text: "create_wallet.error.empty_passphrase".localized, type: .error))
            } else if case CreateAccountViewModelNew.CreateError.invalidConfirmation = error {
                passphraseConfirmationCaution = .caution(Caution(text: "create_wallet.error.invalid_confirmation".localized, type: .error))
            } else {
                HudHelper.instance.show(banner: .error(string: error.smartDescription))
            }
        }
    }
}

extension CreateAccountView {
    enum Field {
        case name
        case passphrase
        case passphraseConfirmation
    }
}
