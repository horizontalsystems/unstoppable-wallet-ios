import SwiftUI

struct BackupPasswordView: View {
    @ObservedObject var viewModel: BackupViewModel
    @StateObject private var passwordViewModel: BackupPasswordViewModel
    @Binding var path: NavigationPath

    @State private var secureLock = true

    init(viewModel: BackupViewModel, path: Binding<NavigationPath>) {
        self.viewModel = viewModel
        _passwordViewModel = StateObject(wrappedValue: BackupPasswordViewModel())
        _path = path
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin32) {
                        Text("backup_app.backup.password.description".localized)
                            .themeSubhead2()
                            .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))

                        VStack(spacing: .margin16) {
                            InputTextRow {
                                InputTextView(
                                    placeholder: "backup.cloud.password.placeholder".localized,
                                    text: $passwordViewModel.password,
                                    isValidText: { PassphraseValidator.validate(text: $0) }
                                )
                                .secure($secureLock)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                            }
                            .modifier(CautionBorder(cautionState: $passwordViewModel.passwordCautionState))
                            .modifier(CautionPrompt(cautionState: $passwordViewModel.passwordCautionState))

                            InputTextRow {
                                InputTextView(
                                    placeholder: "backup.cloud.password.confirm.placeholder".localized,
                                    text: $passwordViewModel.confirm,
                                    isValidText: { PassphraseValidator.validate(text: $0) }
                                )
                                .secure($secureLock)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                            }
                            .modifier(CautionBorder(cautionState: $passwordViewModel.confirmCautionState))
                            .modifier(CautionPrompt(cautionState: $passwordViewModel.confirmCautionState))
                        }
                        .animation(.default, value: secureLock)

                        HighlightedTextView(text: "backup_app.backup.password.highlighted_description".localized, style: .warning)
                    }
                    .animation(.default, value: passwordViewModel.passwordCautionState)
                    .animation(.default, value: passwordViewModel.confirmCautionState)
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                Button(action: {
                    onSave()
                }) {
                    HStack(spacing: .margin8) {
                        if viewModel.processing {
                            ProgressView().progressViewStyle(.circular)
                        }

                        Text("button.save".localized)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(viewModel.processing)
                .animation(.default, value: viewModel.processing)
            }
        }
        .navigationTitle("backup_app.backup.password.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.cancel".localized) {
                viewModel.cancel()
            }
            .disabled(viewModel.processing)
        }
    }

    private func onSave() {
        passwordViewModel.validate()

        guard passwordViewModel.isValid else { return }

        viewModel.setPassword(passwordViewModel.password)
        viewModel.save()
    }
}
