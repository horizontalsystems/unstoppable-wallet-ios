import SwiftUI

struct BackupFormView: View {
    @ObservedObject var viewModel: BackupViewModel
    @StateObject private var nameViewModel: BackupNameViewModel
    @StateObject private var passwordViewModel: BackupPasswordViewModel
    @Binding var path: NavigationPath

    @FocusState private var passwordFocused: Bool

    init(viewModel: BackupViewModel, path: Binding<NavigationPath>) {
        let destination = viewModel.destination ?? .files
        self.viewModel = viewModel
        _nameViewModel = StateObject(wrappedValue: BackupNameViewModel(type: viewModel.type, destination: destination))
        _passwordViewModel = StateObject(wrappedValue: BackupPasswordViewModel(destination: destination, backupViewModel: viewModel))
        _path = path
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin32) {
                        BackupNameContentView(viewModel: nameViewModel)
                        BackupPasswordContentView(viewModel: passwordViewModel, passwordFocused: $passwordFocused)
                    }
                }
            } bottomContent: {
                Button(action: {
                    onTapSave()
                }) {
                    HStack(spacing: .margin8) {
                        if passwordViewModel.processing {
                            ProgressView().progressViewStyle(.circular)
                        }
                        Text("button.save".localized)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(!nameViewModel.isValid || passwordViewModel.processing)
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
        .onReceive(passwordViewModel.showGenerateSheetPublisher) {
            showGenerateSheet()
        }
        .onReceive(passwordViewModel.focusPasswordPublisher) {
            passwordFocused = true
        }
        .onAppear {
            passwordViewModel.onAppear()
        }
    }

    private func onTapSave() {
        viewModel.setName(nameViewModel.name)
        passwordViewModel.setKeychainAccount(nameViewModel.name)
        passwordViewModel.onTapSave()
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
