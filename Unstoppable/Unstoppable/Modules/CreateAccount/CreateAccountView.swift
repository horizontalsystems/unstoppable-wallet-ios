import HdWalletKit
import SwiftUI

struct CreateAccountView: View {
    @StateObject private var viewModel: CreateAccountViewModel

    @Binding var isPresented: Bool
    var onCreate: (() -> Void)?

    @State private var secureLock = true
    @State private var passphraseCaution: CautionState = .none
    @State private var passphraseConfirmationCaution: CautionState = .none

    @FocusState private var focusedField: Field?

    init(walletType: CreateAccountViewModel.WalletType, isPresented: Binding<Bool>, onCreate: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: CreateAccountViewModel(walletType: walletType))
        _isPresented = isPresented
        self.onCreate = onCreate
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: 24) {
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

                        switch viewModel.walletType {
                        case .regular:
                            ListSection {
                                ListRow {
                                    Toggle(isOn: $viewModel.advanced) {
                                        Text("create_wallet.advanced_options".localized).themeBody()
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                                }
                            }

                            if viewModel.advanced {
                                ListSection {
                                    Cell(
                                        middle: {
                                            MultiText(subtitle: "create_wallet.phrase_count".localized)
                                        },
                                        right: {
                                            ThemeText(
                                                "create_wallet.n_words".localized("\(viewModel.wordCount.rawValue)"),
                                                style: .subheadSB
                                            ).arrow(style: .dropdown)
                                        },
                                        action: {
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
                                    )
                                }

                                VStack(spacing: 0) {
                                    ListSectionHeader(text: "create_wallet.passphrase_optional".localized, uppercased: false)

                                    VStack(spacing: 16) {
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
                        case .passkey, .smartAccount: EmptyView()
                        }
                    }
                    .animation(.default, value: viewModel.advanced)
                    .animation(.default, value: viewModel.wordCount)
                    .animation(.default, value: passphraseCaution)
                    .animation(.default, value: passphraseConfirmationCaution)
                    .padding(EdgeInsets(top: 24, leading: 16, bottom: 32, trailing: 16))
                }
                .onTapGesture {
                    focusedField = nil
                }
            } bottomContent: {
                ThemeButton(text: "create_wallet.create".localized) {
                    createAccount()
                }
                .disabled(!viewModel.createEnabled)
            }
        }
        .onChange(of: viewModel.passphrase) { _ in clearCautions() }
        .onChange(of: viewModel.passphraseConfirmation) { _ in clearCautions() }
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

    private func createAccount() {
        focusedField = nil

        switch viewModel.walletType {
        case .regular:
            do {
                let account = try viewModel.createAccount()
                handleSuccess(account: account)
            } catch {
                handleError(error)
            }
        case .passkey:
            Task {
                do {
                    let account = try await viewModel.createPasskeyAccount()
                    await MainActor.run { handleSuccess(account: account) }
                } catch {
                    await MainActor.run { handleError(error) }
                }
            }
        case .smartAccount:
            Task {
                do {
                    let account = try await viewModel.createSmartAccount()
                    await MainActor.run { handleSuccess(account: account) }
                } catch {
                    await MainActor.run { handleError(error) }
                }
            }
        }
    }

    private func handleSuccess(account: Account) {
        HudHelper.instance.show(banner: .created)

        if let onCreate {
            onCreate()
        } else {
            isPresented = false
        }

        if case .regular = viewModel.walletType {
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                BackupRequiredView.afterCreate(account: account, isPresented: isPresented)
            }
        }
    }

    private func handleError(_ error: Error) {
        if case CreateAccountViewModel.CreateError.emptyPassphrase = error {
            passphraseCaution = .caution(Caution(text: "create_wallet.error.empty_passphrase".localized, type: .error))
        } else if case CreateAccountViewModel.CreateError.invalidConfirmation = error {
            passphraseConfirmationCaution = .caution(Caution(text: "create_wallet.error.invalid_confirmation".localized, type: .error))
        } else if case PasskeyManager.PasskeyError.userCanceled = error {
            return
        } else if case SmartAccountPasskeyManager.AAError.userCanceled = error {
            return
        } else {
            HudHelper.instance.show(banner: .error(string: error.smartDescription))
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

struct PasskeyTermsView: View {
    @Binding var isPresented: Bool
    var walletType: CreateAccountViewModel.WalletType = .passkey
    var onCreate: (() -> Void)?

    @State private var checkedIds = Set<String>()
    @State private var createAccountPresented = false

    private let terms = PasskeyTermsView.Term.allCases

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    ListSection {
                        ForEach(terms, id: \.id) { term in
                            row(term: term, checked: checkedIds.contains(term.id))
                        }
                    }
                    .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
                }
            } bottomContent: {
                ThemeButton(text: "passkey_terms.button".localized) {
                    Core.shared.termsManager.setPasskeyTermsAccepted()
                    createAccountPresented = true
                }
                .disabled(checkedIds.count < terms.count)
            }
        }
        .navigationTitle("passkey_terms.title".localized)
        .navigationDestination(isPresented: $createAccountPresented) {
            CreateAccountView(walletType: walletType, isPresented: $isPresented, onCreate: onCreate)
        }
    }

    @ViewBuilder private func row(term: Term, checked: Bool) -> some View {
        Cell(
            left: {
                Image.checkbox(active: checked)
            },
            middle: {
                MultiText(title: term.title, subtitle: term.description)
            },
            action: {
                toggle(term)
            }
        )
    }

    private func toggle(_ term: Term) {
        if checkedIds.contains(term.id) {
            checkedIds.remove(term.id)
        } else {
            checkedIds.insert(term.id)
        }
    }
}

extension PasskeyTermsView {
    enum Term: String, CaseIterable {
        case deviceIcloud
        case crossPlatform
        case responsibility

        var id: String { rawValue }

        var title: String {
            switch self {
            case .deviceIcloud: return "passkey_terms.device_icloud.title".localized
            case .crossPlatform: return "passkey_terms.cross_platform.title".localized
            case .responsibility: return "passkey_terms.responsibility.title".localized
            }
        }

        var description: String {
            switch self {
            case .deviceIcloud: return "passkey_terms.device_icloud.description".localized
            case .crossPlatform: return "passkey_terms.cross_platform.description".localized
            case .responsibility: return "passkey_terms.responsibility.description".localized
            }
        }
    }
}
