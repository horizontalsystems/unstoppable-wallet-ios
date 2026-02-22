import SwiftUI

struct BackupPasswordView: View {
    @ObservedObject var viewModel: BackupViewModel
    @StateObject private var passwordViewModel: BackupPasswordViewModel
    @Binding var path: NavigationPath

    @State private var secureLock = true

    init(viewModel: BackupViewModel, path: Binding<NavigationPath>) {
        _passwordViewModel = StateObject(wrappedValue: BackupPasswordViewModel(destination: viewModel.destination ?? .files))
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
        .onAppear {
            showGeneratePasswordSheet()
        }
    }

    private func showGeneratePasswordSheet() {
        let name = viewModel.name
        guard !name.isEmpty else { return }

        passwordViewModel.prepareKeychain(name: name)

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
        }
    }

    private func onSave() {
        Task {
            defer { viewModel.set(processing: false) }

            do {
                try await passwordViewModel.saveIfNeeded()

                viewModel.set(password: passwordViewModel.password)
                try await viewModel.save()
                
                viewModel.set(processing: false)    // discard processing after successful
            } catch {
                await handle(error: error)
            }
        }
    }
    
    private func handle(error: Error) async {
        var errorDescription: String?
        if let error = error as? BackupPasswordViewModel.ValidationError {  // check if not validated
            switch error {
            case .invalid: ()
            case .emptyKeychainAccount: errorDescription = "Keychain Empty Error!"
            }
        } else {
            errorDescription = error.localizedDescription
        }

        if let errorDescription {
            await MainActor.run {
                HudHelper.instance.show(banner: .error(string: errorDescription))
            }
        }
    }
}

extension BackupModule.Destination {
    fileprivate var passwordTitle: String {
        switch self {
        case .cloud: return "backup.password.generate.title.cloud".localized
        case .files: return "backup.password.generate.title.files".localized
        }
    }

    fileprivate var passwordDescription: String {
        switch self {
        case .cloud: return "backup.password.generate.description.cloud".localized
        case .files: return "backup.password.generate.description.files".localized
        }
    }

    fileprivate var passwordAction: String {
        switch self {
        case .cloud: return "backup.password.generate.action.cloud".localized
        case .files: return "backup.password.generate.action.files".localized
        }
    }
}
