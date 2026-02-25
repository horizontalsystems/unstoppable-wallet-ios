import SwiftUI

struct BackupPasswordContentView: View {
    @ObservedObject var viewModel: BackupPasswordViewModel
    var passwordFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: .margin32) {
            Text("backup_app.backup.password.description".localized)
                .themeSubhead2()
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))

            VStack(spacing: .margin16) {
                InputTextRow {
                    InputTextView(
                        placeholder: "backup.cloud.password.placeholder".localized,
                        text: $viewModel.password,
                        isValidText: { PassphraseValidator.validate(text: $0) }
                    )
                    .secure($viewModel.secureLock)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused(passwordFocused)
                }
                .modifier(CautionBorder(cautionState: $viewModel.passwordCautionState))
                .modifier(CautionPrompt(cautionState: $viewModel.passwordCautionState))

                InputTextRow {
                    InputTextView(
                        placeholder: "backup.cloud.password.confirm.placeholder".localized,
                        text: $viewModel.confirm,
                        isValidText: { PassphraseValidator.validate(text: $0) }
                    )
                    .secure($viewModel.secureLock)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }
                .modifier(CautionBorder(cautionState: $viewModel.confirmCautionState))
                .modifier(CautionPrompt(cautionState: $viewModel.confirmCautionState))
            }
            .animation(.default, value: viewModel.secureLock)

            HighlightedTextView(
                text: "backup_app.backup.password.highlighted_description".localized,
                style: .warning
            )
        }
        .animation(.default, value: viewModel.passwordCautionState)
        .animation(.default, value: viewModel.confirmCautionState)
        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
    }
}
