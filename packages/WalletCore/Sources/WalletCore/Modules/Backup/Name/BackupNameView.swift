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
                    BackupNameContentView(viewModel: nameViewModel)
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
        path.append(BackupModule.Step.form)
    }
}
