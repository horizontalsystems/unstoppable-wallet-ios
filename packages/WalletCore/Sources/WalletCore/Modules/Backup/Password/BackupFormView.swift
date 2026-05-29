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
                    VStack(spacing: .margin12) {
                        ThemeText("backup_app.backup.form.description".localized, style: .subhead)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, .margin16)
                            .padding(.bottom, .margin16)

                        BackupNameContentView(viewModel: nameViewModel)
                        BackupPasswordContentView(viewModel: passwordViewModel, passwordFocused: $passwordFocused)
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
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
        .navigationTitle("backup_app.backup.form.title".localized)
        .onReceive(passwordViewModel.showGenerateSheetPublisher) {
            showGenerateSheet()
        }
    }

    private func onTapSave() {
        viewModel.setName(nameViewModel.name)
        passwordViewModel.setKeychainAccount(nameViewModel.name)
        passwordViewModel.onTapSave()
    }

    private func showGenerateSheet() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(items: [
                .title(icon: ThemeImage.key, title: "backup.password.generate.title.cloud".localized),
                .text(text: "backup.password.generate.description.cloud".localized),
                .buttonGroup(.init(buttons: [
                    .init(style: .gray, title: "backup.password.generate.action.cloud".localized) {
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
            if passwordViewModel.passwordState != .willSave {
                passwordFocused = true
            }
        }
    }
}
