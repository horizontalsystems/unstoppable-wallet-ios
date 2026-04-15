import SwiftUI

struct RestorePassphraseView: View {
    @StateObject private var viewModel: RestorePassphraseViewModel
    @Binding private var isParentPresented: Bool

    @State private var secureLock = true
    @FocusState private var focused: Bool

    @State private var restoreSelectAccount: Account?
    @State private var restoreSelectPresented = false
    @State private var rawBackup: RawFullBackup?
    @State private var configurationPresented = false

    init(
        item: BackupModule.NamedSource,
        isParentPresented: Binding<Bool>
    ) {
        _viewModel = StateObject(wrappedValue: RestorePassphraseViewModel(restoredBackup: item))
        _isParentPresented = isParentPresented
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin32) {
                        HStack {
                            ThemeText("restore.cloud.password.description".localized, style: .subhead)
                            Spacer()
                        }
                        .padding(.horizontal, .margin16)

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
        .navigationTitle(viewModel.restoredBackup.name)
        .navigationDestination(isPresented: $restoreSelectPresented) {
            if let restoreSelectAccount {
                RestoreSelectWrapper(
                    accountName: restoreSelectAccount.name,
                    accountType: restoreSelectAccount.type,
                    statPage: .importWallet,
                    isManualBackedUp: restoreSelectAccount.backedUp,
                    isFileBackedUp: restoreSelectAccount.fileBackedUp,
                    onRestore: { isParentPresented = false }
                )
                .ignoresSafeArea()
                .navigationTitle("restore.title".localized)
            }
        }
        .navigationDestination(isPresented: $configurationPresented) {
            if let rawBackup {
                RestoreFileConfigurationView(
                    rawBackup: rawBackup,
                    backupName: viewModel.restoredBackup.name,
                    isParentPresented: $isParentPresented,
                    statPage: .importWallet
                )
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
            stat(page: .importWallet, event: .importWallet(walletType: accountType.statDescription))
            isParentPresented = false
        }
        .onReceive(viewModel.openSelectCoinsPublisher) { account in
            restoreSelectAccount = account
            restoreSelectPresented = true
        }
        .onReceive(viewModel.openConfigurationPublisher) { rawBackup in
            self.rawBackup = rawBackup
            configurationPresented = true
        }
    }
}
