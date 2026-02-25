import SwiftUI

struct BackupPasswordView: View {
    @ObservedObject var viewModel: BackupViewModel
    @StateObject private var passwordViewModel: BackupPasswordViewModel
    @Binding var path: NavigationPath

    @FocusState private var passwordFocused: Bool

    init(viewModel: BackupViewModel, path: Binding<NavigationPath>) {
        let destination = viewModel.destination ?? .files
        _passwordViewModel = StateObject(wrappedValue: BackupPasswordViewModel(destination: destination, backupViewModel: viewModel))
        self.viewModel = viewModel
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
                                .secure($passwordViewModel.secureLock)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($passwordFocused)
                            }
                            .modifier(CautionBorder(cautionState: $passwordViewModel.passwordCautionState))
                            .modifier(CautionPrompt(cautionState: $passwordViewModel.passwordCautionState))

                            InputTextRow {
                                InputTextView(
                                    placeholder: "backup.cloud.password.confirm.placeholder".localized,
                                    text: $passwordViewModel.confirm,
                                    isValidText: { PassphraseValidator.validate(text: $0) }
                                )
                                .secure($passwordViewModel.secureLock)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                            }
                            .modifier(CautionBorder(cautionState: $passwordViewModel.confirmCautionState))
                            .modifier(CautionPrompt(cautionState: $passwordViewModel.confirmCautionState))
                        }
                        .animation(.default, value: passwordViewModel.secureLock)

                        HighlightedTextView(
                            text: "backup_app.backup.password.highlighted_description".localized,
                            style: .warning
                        )
                    }
                    .animation(.default, value: passwordViewModel.passwordCautionState)
                    .animation(.default, value: passwordViewModel.confirmCautionState)
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                Button(action: {
                    passwordViewModel.onTapSave()
                }) {
                    HStack(spacing: .margin8) {
                        if passwordViewModel.processing {
                            ProgressView().progressViewStyle(.circular)
                        }
                        Text("button.save".localized)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(passwordViewModel.processing)
                .animation(.default, value: passwordViewModel.processing)
            }
        }
        .navigationTitle("backup_app.backup.password.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.cancel".localized) {
                viewModel.cancel()
            }
            .disabled(passwordViewModel.processing)
        }
        .onAppear {
            passwordViewModel.onAppear()
        }
        .onReceive(passwordViewModel.showGenerateSheetPublisher) {
            showGenerateSheet()
        }
        .onReceive(passwordViewModel.showWarningSheetPublisher) {
            showWarningSheet()
        }
        .onReceive(passwordViewModel.focusPasswordPublisher) {
            passwordFocused = true
        }
    }

    private func showGenerateSheet() {
        let destination = viewModel.destination ?? .files

        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(items: [
                .title(icon: ThemeImage.cloud, title: destination.passwordTitle),
                .text(text: destination.passwordDescription),
                .buttonGroup(.init(buttons: [
                    .init(style: .yellow, title: destination.passwordAction) {
                        do {
                            try passwordViewModel.useGeneratedPassword()
                        } catch {
                            HudHelper.instance.show(banner: .error(string: error.localizedDescription))
                        }
                        isPresented.wrappedValue = false
                    },
                ])),
            ])
        } onDismiss: {
            passwordViewModel.onGenerateSheetDismissed()
        }
    }

    private func showWarningSheet() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(items: [
                .title(icon: ThemeImage.warning, title: "Save Password"),
                .text(text: "Make sure you saved the password. Without it, access to the backup file will be lost."),
                .buttonGroup(.init(buttons: [
                    .init(style: .gray, title: "Check Again") {
                        isPresented.wrappedValue = false
                    },
                    .init(style: .yellow, title: "Just Make Backup") {
                        isPresented.wrappedValue = false
                        passwordViewModel.confirmSave()
                    },
                ])),
            ])
        }
    }
}

private extension BackupModule.Destination {
    var passwordTitle: String {
        switch self {
        case .cloud: return "backup.password.generate.title.cloud".localized
        case .files: return "backup.password.generate.title.files".localized
        }
    }

    var passwordDescription: String {
        switch self {
        case .cloud: return "backup.password.generate.description.cloud".localized
        case .files: return "backup.password.generate.description.files".localized
        }
    }

    var passwordAction: String {
        switch self {
        case .cloud: return "backup.password.generate.action.cloud".localized
        case .files: return "backup.password.generate.action.files".localized
        }
    }
}
