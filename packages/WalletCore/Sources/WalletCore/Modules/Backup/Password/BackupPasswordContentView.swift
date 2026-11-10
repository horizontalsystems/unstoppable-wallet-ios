import SwiftUI

struct BackupPasswordContentView: View {
    @ObservedObject var viewModel: BackupPasswordViewModel
    @Binding var passwordFocused: Bool

    @State private var confirmFocused = false

    var body: some View {
        VStack(spacing: .margin16) {
            VStack(spacing: 0) {
                ListSectionHeader(text: "backup_app.backup.password.title".localized, uppercased: false, insets: .zero)

                passwordField
                    .animation(.default, value: viewModel.secureLock)
            }
            .animation(.default, value: viewModel.passwordCautionState)

            VStack(spacing: 0) {
                confirmField
                    .animation(.default, value: viewModel.secureLock)
            }
            .animation(.default, value: viewModel.confirmCautionState)
        }
    }

    private var passwordField: some View {
        ThemeInput(
            caution: viewModel.passwordCautionState,
            buttons: [.secureToggle($viewModel.secureLock, identifier: TestTags.backupPasswordEye)]
        ) {
            InputTextView(
                placeholder: "backup.cloud.password.placeholder".localized,
                text: $viewModel.password,
                isValidText: { PassphraseValidator.validate(text: $0) }
            )
            .secure($viewModel.secureLock, identifier: TestTags.backupPasswordInput, isFocused: $passwordFocused)
            .autocapitalization(.none)
            .autocorrectionDisabled()
        }
        .modifier(KeychainHighlight(active: viewModel.passwordState == .willSave))
        .tapIntercept(active: !viewModel.passwordState.isInteractive) { viewModel.onTapPasswordField() }
    }

    private var confirmField: some View {
        ThemeInput(
            caution: viewModel.confirmCautionState,
            buttons: [.secureToggle($viewModel.secureLock, identifier: TestTags.backupPasswordConfirmEye)]
        ) {
            InputTextView(
                placeholder: "backup.cloud.password.confirm.placeholder".localized,
                text: $viewModel.confirm,
                isValidText: { PassphraseValidator.validate(text: $0) }
            )
            .secure($viewModel.secureLock, identifier: TestTags.backupPasswordConfirmInput, isFocused: $confirmFocused)
            .autocapitalization(.none)
            .autocorrectionDisabled()
        }
        .modifier(KeychainHighlight(active: viewModel.passwordState == .willSave))
        .tapIntercept(active: !viewModel.passwordState.isInteractive) { viewModel.onTapPasswordField() }
    }
}

struct KeychainHighlight: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous)
                .fill(Color.themeBrand.opacity(active ? 0.2 : 0))
                .allowsHitTesting(false)
        )
    }
}
