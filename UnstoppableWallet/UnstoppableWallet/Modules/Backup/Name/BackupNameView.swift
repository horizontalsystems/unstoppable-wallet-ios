import SwiftUI

struct BackupNameView: View {
    @ObservedObject var viewModel: BackupViewModel
    @StateObject private var nameViewModel: BackupNameViewModel
    @Binding var path: NavigationPath

    init(viewModel: BackupViewModel, path: Binding<NavigationPath>) {
        self.viewModel = viewModel
        _nameViewModel = StateObject(wrappedValue: BackupNameViewModel(type: viewModel.type, destination: viewModel.destination ?? .files))
        _path = path
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin24) {
                        Text("backup_app.backup.name.description".localized)
                            .themeSubhead2()
                            .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin12, trailing: .margin16))

                        InputTextRow {
                            InputTextView(
                                placeholder: "backup.cloud.name.placeholder".localized,
                                text: $nameViewModel.name
                            )
                            .autocapitalization(.words)
                            .autocorrectionDisabled()
                        }
                        .modifier(CautionBorder(cautionState: $nameViewModel.cautionState))
                        .modifier(CautionPrompt(cautionState: $nameViewModel.cautionState))
                    }
                    .animation(.default, value: nameViewModel.cautionState)
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                Button(action: {
                    onNext()
                }) {
                    Text("button.next".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(!nameViewModel.isValid)
            }
        }
        .navigationTitle("backup_app.backup.name.title".localized)
    }

    private func onNext() {
        viewModel.setName(nameViewModel.name)
        path.append(BackupModule.Step.password)
    }
}
