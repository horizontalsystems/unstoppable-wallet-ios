import SwiftUI

struct BackupNameContentView: View {
    @ObservedObject var viewModel: BackupNameViewModel

    var body: some View {
        VStack(spacing: .margin24) {
            Text("backup_app.backup.name.description".localized)
                .themeSubhead2()
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin12, trailing: .margin16))

            InputTextRow {
                InputTextView(
                    placeholder: "backup.cloud.name.placeholder".localized,
                    text: $viewModel.name
                )
                .autocapitalization(.words)
                .autocorrectionDisabled()
            }
            .modifier(CautionBorder(cautionState: $viewModel.cautionState))
            .modifier(CautionPrompt(cautionState: $viewModel.cautionState))
        }
        .animation(.default, value: viewModel.cautionState)
        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
    }
}
