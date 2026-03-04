import SwiftUI

struct BackupNameContentView: View {
    @ObservedObject var viewModel: BackupNameViewModel

    var body: some View {
        VStack {
            ListSection(header: "backup_app.backup.name.title".localized, uppercased: false) {
                InputTextRow {
                    ShortcutButtonsView(
                        content: {
                            InputTextView(
                                placeholder: "backup.cloud.name.placeholder".localized,
                                text: $viewModel.name,
                                isValidText: { BackupFilenameValidator.isValidFilename($0) }
                            )
                            .autocapitalization(.words)
                            .autocorrectionDisabled()
                        },
                        showDelete: .init(get: { !viewModel.name.isEmpty }, set: { _ in }),
                        items: [.text("button.paste".localized)],
                        onTap: { _ in
                            if let text = UIPasteboard.general.string {
                                viewModel.name = text
                            }
                        },
                        onTapDelete: {
                            viewModel.name = ""
                        }
                    )
                }
                .modifier(CautionBorder(cautionState: $viewModel.cautionState))
                .modifier(CautionPrompt(cautionState: $viewModel.cautionState))
            }
        }
        .animation(.default, value: viewModel.cautionState)
    }
}
