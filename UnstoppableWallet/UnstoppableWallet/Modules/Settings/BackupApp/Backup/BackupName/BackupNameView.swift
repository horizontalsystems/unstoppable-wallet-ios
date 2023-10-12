import SwiftUI
import ThemeKit

struct BackupNameView: View {
    @ObservedObject var viewModel: BackupAppViewModel
    var onDismiss: (() -> Void)?

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
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
                    .modifier(CautionBorder(cautionState: $viewModel.nameCautionState))
                    .modifier(CautionPrompt(cautionState: $viewModel.nameCautionState))
                }
                .animation(.default, value: viewModel.nameCautionState)
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            } bottomContent: {
                NavigationLink(
                    destination: BackupPasswordView(viewModel: viewModel, onDismiss: onDismiss),
                    isActive: $viewModel.passwordPushed
                ) {
                    Button(action: {
                        viewModel.passwordPushed = true
                    }) {
                        Text("button.next".localized)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(viewModel.nameCautionState != .none)
            }
            .navigationTitle("backup_app.backup.name.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.cancel".localized) {
                    onDismiss?()
                }
            }
        }
    }
}
