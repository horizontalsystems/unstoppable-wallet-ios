import SwiftUI

struct RestorePassphraseView: View {
    @StateObject private var viewModel: RestorePassphraseViewModel
    @Binding var isPresented: Bool

    private let statPage: StatPage
    private let onSelectCoins: (Account) -> Void
    private let onConfiguration: (RawFullBackup) -> Void
    private let onRestore: () -> Void

    @State private var secureLock = true
    @FocusState private var focused: Bool

    init(
        item: BackupModule.NamedSource,
        statPage: StatPage,
        isPresented: Binding<Bool>,
        onSelectCoins: @escaping (Account) -> Void,
        onConfiguration: @escaping (RawFullBackup) -> Void,
        onRestore: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: RestorePassphraseViewModel(restoredBackup: item))
        _isPresented = isPresented
        self.statPage = statPage
        self.onSelectCoins = onSelectCoins
        self.onConfiguration = onConfiguration
        self.onRestore = onRestore
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin32) {
                        Text("restore.cloud.password.description".localized)
                            .themeSubhead2()

                        InputTextRow {
                            InputTextView(
                                placeholder: "restore.cloud.password.placeholder".localized,
                                text: $viewModel.passphrase,
                                isValidText: { PassphraseValidator.validate(text: $0) }
                            )
                            .secure($secureLock)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focused)
                        }
                        .modifier(CautionBorder(cautionState: $viewModel.passphraseCautionState))
                        .modifier(CautionPrompt(cautionState: $viewModel.passphraseCautionState))
                    }
                    .animation(.default, value: viewModel.passphraseCautionState)
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                Button(action: {
                    viewModel.onTapNext()
                }) {
                    HStack(spacing: .margin8) {
                        if viewModel.processing {
                            ProgressView().progressViewStyle(.circular)
                        }
                        Text(viewModel.buttonTitle)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(viewModel.processing)
                .animation(.default, value: viewModel.processing)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onReceive(viewModel.focusPublisher) { shouldFocus in
            focused = shouldFocus
        }
        .onReceive(viewModel.unlockAndSetPasswordPublisher) { password in
            Coordinator.shared.performAfterUnlock { [weak viewModel] in
//                HudHelper.instance.show(banner: .passwordFromKeychain)
                viewModel?.setPassphrase(password)
            }
        }
        .onReceive(viewModel.showErrorPublisher) { error in
            HudHelper.instance.show(banner: .error(string: error))
        }
        .onReceive(viewModel.successPublisher) { accountType in
            HudHelper.instance.show(banner: .imported)
            stat(page: statPage, event: .importWallet(walletType: accountType.statDescription))
            onRestore()
        }
        .onReceive(viewModel.openSelectCoinsPublisher) { account in
            onSelectCoins(account)
        }
        .onReceive(viewModel.openConfigurationPublisher) { rawBackup in
            onConfiguration(rawBackup)
        }
        .navigationTitle("restore.cloud.password.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.cancel".localized) {
                    isPresented = false
                }
                .disabled(viewModel.processing)
            }
        }
    }
}
