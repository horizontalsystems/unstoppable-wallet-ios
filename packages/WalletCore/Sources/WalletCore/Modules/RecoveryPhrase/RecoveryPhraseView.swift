import SwiftUI

struct RecoveryPhraseView: View {
    @StateObject private var viewModel: RecoveryPhraseViewModel

    init(account: Account) {
        _viewModel = StateObject(wrappedValue: RecoveryPhraseViewModel(account: account))
    }

    var body: some View {
        KeyScreenScaffold(
            title: "recovery_phrase.title".localized,
            statPage: .recoveryPhrase,
            copyDisabled: viewModel.words.isEmpty,
            onCopy: { viewModel.copy() }
        ) {
            VStack(spacing: .margin12) {
                AlertCardView(.init(text: "recovery_phrase.warning".localized(AppConfig.appName), type: .caution, style: .inline))

                MnemonicPhraseView(
                    words: viewModel.words,
                    hidden: viewModel.hidden,
                    hint: "recovery_phrase.tap_to_show".localized
                ) {
                    viewModel.toggleHidden()
                }

                if let passphrase = viewModel.passphrase {
                    ListSection {
                        ListRow {
                            ThemeImage("key", size: 20, colorStyle: .secondary)
                            ThemeText("recovery_phrase.passphrase".localized, style: .subhead)

                            Spacer()

                            ThemeButton(text: viewModel.hidden ? BalanceHiddenManager.placeholder : passphrase, style: .secondary, size: .small) {
                                viewModel.copyPassphrase()
                            }
                            .accessibilityLabel(viewModel.hidden ? "recovery_phrase.passphrase".localized : passphrase)
                        }
                    }
                    .padding(.top, .margin12)
                }
            }
        }
    }
}
