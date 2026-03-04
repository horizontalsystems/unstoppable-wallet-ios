import SwiftUI

struct BackupPasswordContentView: View {
    @ObservedObject var viewModel: BackupPasswordViewModel
    var passwordFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: .margin12) {
            Text("backup_app.backup.password.title".localized)
                .themeSubhead2()
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))

            VStack(spacing: .margin16) {
                passwordField
                confirmField
            }
            .animation(.default, value: viewModel.secureLock)
        }
        .animation(.default, value: viewModel.passwordCautionState)
        .animation(.default, value: viewModel.confirmCautionState)
        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
    }

    private var passwordField: some View {
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
        .modifier(KeychainHighlight(active: viewModel.passwordState == .willSave))
        .modifier(CautionBorder(cautionState: $viewModel.passwordCautionState))
        .modifier(CautionPrompt(cautionState: $viewModel.passwordCautionState))
        .overlay(tapInterceptor)
    }

    private var confirmField: some View {
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
        .modifier(KeychainHighlight(active: viewModel.passwordState == .willSave))
        .modifier(CautionBorder(cautionState: $viewModel.confirmCautionState))
        .modifier(CautionPrompt(cautionState: $viewModel.confirmCautionState))
        .overlay(tapInterceptor)
    }

    @ViewBuilder
    private var tapInterceptor: some View {
        if !viewModel.passwordState.isInteractive {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { viewModel.onTapPasswordField() }
        }
    }
}

struct KeychainHighlight: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
                .fill(Color.themeJacob.opacity(active ? 0.2 : 0))
                .allowsHitTesting(false)
        )
    }
}
