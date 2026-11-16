import HdWalletKit
import SwiftUI

struct CreateAccountView: View {
    @StateObject private var viewModel: CreateAccountViewModel

    @Binding var isPresented: Bool

    @State private var secureLock = true
    @State private var passphraseCaution: CautionState = .none
    @State private var passphraseConfirmationCaution: CautionState = .none

    @FocusState private var focusedField: Field?
    // the masked passphrase fields are UIKit text fields that @FocusState does not track
    @State private var passphraseFocused = false
    @State private var passphraseConfirmationFocused = false

    init(walletType: CreateAccountViewModel.WalletType, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: CreateAccountViewModel(walletType: walletType))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 0) {
                            ListSectionHeader(text: "create_wallet.name".localized, uppercased: false)

                            ThemeInput(
                                buttons: [
                                    .icon("swap_e", identifier: TestTags.createNameRandom) {
                                        viewModel.refreshName()
                                    },
                                ]
                            ) {
                                InputTextView(text: $viewModel.name)
                                    .autocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .name)
                                    .accessibilityIdentifier(TestTags.createNameInput)
                            }
                        }

                        switch viewModel.walletType {
                        case .regular:
                            ListSection {
                                Cell(
                                    middle: { ThemeText("create_wallet.advanced_options".localized, style: .headline2) },
                                    right: { ThemeToggle(isOn: $viewModel.advanced) }
                                )
                            }

                            if viewModel.advanced {
                                ListSection {
                                    Cell(
                                        middle: {
                                            MultiText(subtitle: "create_wallet.phrase_count".localized)
                                        },
                                        right: {
                                            DropdownButton(text: "create_wallet.n_words".localized("\(viewModel.wordCount.rawValue)"), mode: .transparent) {
                                                Coordinator.shared.present(type: .alert) { isPresented in
                                                    OptionAlertView(
                                                        title: "create_wallet.phrase_count".localized,
                                                        viewItems: Mnemonic.WordCount.allCases.map {
                                                            .init(text: title(wordCount: $0), selected: $0 == viewModel.wordCount)
                                                        },
                                                        onSelect: { index in
                                                            viewModel.wordCount = Mnemonic.WordCount.allCases[index]
                                                        },
                                                        isPresented: isPresented
                                                    )
                                                }
                                            }
                                        }
                                    )
                                }

                                VStack(spacing: 0) {
                                    ListSectionHeader(text: "create_wallet.passphrase_optional".localized, uppercased: false)

                                    VStack(spacing: 16) {
                                        ThemeInput(
                                            caution: passphraseCaution,
                                            buttons: [.secureToggle($secureLock, identifier: TestTags.createPassphraseEye)]
                                        ) {
                                            InputTextView(
                                                placeholder: "create_wallet.input.passphrase".localized,
                                                text: $viewModel.passphrase,
                                                isValidText: { text in PassphraseValidator.validate(text: text) }
                                            )
                                            .secure($secureLock, identifier: TestTags.createPassphraseInput, isFocused: $passphraseFocused)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                        }

                                        ThemeInput(
                                            caution: passphraseConfirmationCaution,
                                            buttons: [.secureToggle($secureLock, identifier: TestTags.createPassphraseConfirmEye)]
                                        ) {
                                            InputTextView(
                                                placeholder: "create_wallet.input.confirm".localized,
                                                text: $viewModel.passphraseConfirmation,
                                                isValidText: { text in PassphraseValidator.validate(text: text) }
                                            )
                                            .secure($secureLock, identifier: TestTags.createPassphraseConfirmInput, isFocused: $passphraseConfirmationFocused)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                        }
                                    }
                                    .animation(.default, value: secureLock)

                                    ListSectionFooter(text: "create_wallet.passphrase_description".localized)
                                }
                            }
                        case .passkey: EmptyView()
                        }
                    }
                    .animation(.default, value: viewModel.advanced)
                    .animation(.default, value: viewModel.wordCount)
                    .animation(.default, value: passphraseCaution)
                    .animation(.default, value: passphraseConfirmationCaution)
                    .padding(EdgeInsets(top: 24, leading: 16, bottom: 32, trailing: 16))
                }
                .onTapGesture {
                    dismissKeyboard()
                }
            } bottomContent: {
                ThemeButton(text: "create_wallet.create".localized) {
                    createAccount()
                }
                .disabled(!viewModel.createEnabled)
                .accessibilityIdentifier(TestTags.createSubmit)
            }
        }
        .onChange(of: viewModel.passphrase) { _, _ in clearCautions() }
        .onChange(of: viewModel.passphraseConfirmation) { _, _ in clearCautions() }
        .navigationTitle("create_wallet.title".localized)
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

    private func dismissKeyboard() {
        focusedField = nil
        passphraseFocused = false
        passphraseConfirmationFocused = false
    }

    private func createAccount() {
        dismissKeyboard()

        switch viewModel.walletType {
        case .regular:
            do {
                _ = try viewModel.createAccount()
                handleSuccess()
            } catch {
                handleError(error)
            }
        case .passkey:
            Task {
                do {
                    _ = try await viewModel.createPasskeyAccount()
                    await MainActor.run { handleSuccess() }
                } catch {
                    await MainActor.run { handleError(error) }
                }
            }
        }
    }

    private func handleSuccess() {
        HudHelper.instance.show(banner: .created)

        isPresented = false
    }

    private func handleError(_ error: Error) {
        if case CreateAccountViewModel.CreateError.emptyPassphrase = error {
            passphraseCaution = .caution(Caution(text: "create_wallet.error.empty_passphrase".localized, type: .error))
        } else if case CreateAccountViewModel.CreateError.invalidConfirmation = error {
            passphraseConfirmationCaution = .caution(Caution(text: "create_wallet.error.invalid_confirmation".localized, type: .error))
        } else if case PasskeyManager.PasskeyError.userCanceled = error {
            return
        } else {
            HudHelper.instance.show(banner: .error(string: error.smartDescription))
        }
    }
}

extension CreateAccountView {
    enum Field {
        case name
    }
}
