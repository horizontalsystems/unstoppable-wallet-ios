import SwiftUI

struct BackupManualView: View {
    @StateObject private var viewModel: BackupManualViewModel
    @Binding private var isPresented: Bool
    private let onComplete: (() -> Void)?

    @State private var verifyPresented = false

    init(account: Account, isPresented: Binding<Bool>, onComplete: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: BackupManualViewModel(account: account))
        _isPresented = isPresented
        self.onComplete = onComplete
    }

    var body: some View {
        ThemeNavigationStack {
            KeyScreenScaffold(
                title: "backup.title".localized,
                statPage: .manualBackup,
                buttonTitle: "backup.verify".localized,
                buttonIdentifier: TestTags.backupVerify,
                buttonDisabled: !viewModel.canVerify,
                onButtonTap: { verifyPresented = true }
            ) {
                VStack(spacing: 0) {
                    ListSectionFooter(text: "backup.description".localized)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, .margin32)

                    MnemonicPhraseView(
                        words: viewModel.words,
                        hidden: viewModel.hidden,
                        hint: "backup.tap_to_show".localized
                    ) {
                        viewModel.toggleHidden()
                    }

                    if let passphrase = viewModel.passphrase {
                        ListSection {
                            Cell(
                                left: { ThemeImage("key", size: .iconSize20) },
                                middle: { ThemeText("backup.passphrase".localized, style: .subhead) },
                                right: {
                                    ThemeButton(text: viewModel.hidden ? BalanceHiddenManager.placeholder : passphrase, style: .secondary, size: .small) {
                                        viewModel.copyPassphrase()
                                    }
                                    .accessibilityLabel(viewModel.hidden ? "backup.passphrase".localized : passphrase)
                                }
                            )
                        }
                        .padding(.top, .margin24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
            .navigationDestination(isPresented: $verifyPresented) {
                BackupVerifyWordsView(account: viewModel.account, isPresented: $isPresented, onComplete: onComplete)
            }
        }
    }
}
