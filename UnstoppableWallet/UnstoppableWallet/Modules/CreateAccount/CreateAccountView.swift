import HdWalletKit
import SwiftUI

struct CreateAccountView: View {
    @StateObject private var viewModel: CreateAccountViewModel

    @Binding var isParentPresented: Bool
    var onCreate: (() -> Void)?

    @State private var secureLock = true
    @State private var passphraseCaution: CautionState = .none
    @State private var passphraseConfirmationCaution: CautionState = .none
    @State private var passkeyTermsPresented = false

    @FocusState private var focusedField: Field?

    init(walletType: CreateAccountViewModel.WalletType, isParentPresented: Binding<Bool>, onCreate: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: CreateAccountViewModel(walletType: walletType))
        _isParentPresented = isParentPresented
        self.onCreate = onCreate
    }

    var body: some View {
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

                        switch viewModel.walletType {
                        case .regular:
                            ListSection {
                                ListRow {
                                    Toggle(isOn: $viewModel.advanced) {
                                        Text("create_wallet.advanced".localized).themeBody()
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                                }
                            }

                            if viewModel.advanced {
                                ListSection {
                                    ClickableRow(spacing: .margin8, action: {
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
                        case .passkey: EmptyView()
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
                Button(action: {
                    createAccount()
                }) {
                    Text("create_wallet.create".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
        }
        .onChange(of: viewModel.passphrase) { _ in clearCautions() }
        .onChange(of: viewModel.passphraseConfirmation) { _ in clearCautions() }
        .navigationTitle("create_wallet.title".localized)
        .navigationDestination(isPresented: $passkeyTermsPresented) {
            PasskeyTermsView(onAccept: {
                passkeyTermsPresented = false
                proceedCreate()
            })
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

        if viewModel.walletType == .passkey, !Core.shared.termsManager.passkeyTermsAccepted {
            passkeyTermsPresented = true
            return
        }

        proceedCreate()
    }

    private func proceedCreate() {
        Task {
            do {
                let account: Account

                switch viewModel.walletType {
                case .regular:
                    account = try viewModel.createAccount()
                case .passkey:
                    account = try await viewModel.createPasskeyAccount()
                }

                DispatchQueue.main.async {
                    HudHelper.instance.show(banner: .created)

                    if let onCreate {
                        onCreate()
                    } else {
                        isParentPresented = false
                    }

                    switch viewModel.walletType {
                    case .regular:
                        Coordinator.shared.present(type: .bottomSheet) { isPresented in
                            BackupRequiredView.afterCreate(account: account, isPresented: isPresented)
                        }
                    case .passkey:
                        ()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if case CreateAccountViewModel.CreateError.emptyPassphrase = error {
                        passphraseCaution = .caution(Caution(text: "create_wallet.error.empty_passphrase".localized, type: .error))
                    } else if case CreateAccountViewModel.CreateError.invalidConfirmation = error {
                        passphraseConfirmationCaution = .caution(Caution(text: "create_wallet.error.invalid_confirmation".localized, type: .error))
                    } else {
                        HudHelper.instance.show(banner: .error(string: error.smartDescription))
                    }
                }
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

struct PasskeyTermsView: View {
    let onAccept: () -> Void

    @State private var checkedIds = Set<String>()

    private let terms = PasskeyTermsView.Term.allCases

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin24) {
                        HStack {
                            ThemeText("passkey_terms.description".localized, style: .subhead)
                            Spacer()
                        }
                        .padding(.horizontal, .margin16)

                        ListSection {
                            ForEach(terms, id: \.id) { term in
                                row(term: term, checked: checkedIds.contains(term.id))
                            }
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                Button(action: {
                    Core.shared.termsManager.setPasskeyTermsAccepted()
                    onAccept()
                }) {
                    Text("passkey_terms.button".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(checkedIds.count < terms.count)
            }
        }
        .navigationTitle("passkey_terms.title".localized)
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
        case recoverySeed
        case crossPlatform
        case responsibility

        var id: String { rawValue }

        var title: String {
            switch self {
            case .deviceIcloud: return "passkey_terms.device_icloud.title".localized
            case .recoverySeed: return "passkey_terms.recovery_seed.title".localized
            case .crossPlatform: return "passkey_terms.cross_platform.title".localized
            case .responsibility: return "passkey_terms.responsibility.title".localized
            }
        }

        var description: String {
            switch self {
            case .deviceIcloud: return "passkey_terms.device_icloud.description".localized
            case .recoverySeed: return "passkey_terms.recovery_seed.description".localized
            case .crossPlatform: return "passkey_terms.cross_platform.description".localized
            case .responsibility: return "passkey_terms.responsibility.description".localized
            }
        }
    }
}
