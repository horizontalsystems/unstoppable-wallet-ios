import SwiftUI

struct BackupNameContentView: View {
    @ObservedObject var viewModel: BackupNameViewModel

    var body: some View {
        VStack(spacing: 0) {
            ListSectionHeader(text: "backup_app.backup.name.title".localized, uppercased: false, insets: .zero)

            ThemeInput(
                caution: viewModel.cautionState,
                buttons: ThemeInputButton.shortcuts(
                    isEmpty: viewModel.name.isEmpty,
                    whenEmpty: [
                        .paste(identifier: TestTags.backupNamePaste) { text in
                            viewModel.name = text
                        },
                    ],
                    deleteIdentifier: TestTags.backupNameClear,
                    onDelete: {
                        viewModel.name = ""
                    }
                )
            ) {
                InputTextView(
                    placeholder: "backup.cloud.name.placeholder".localized,
                    text: $viewModel.name,
                    isValidText: { BackupFilenameValidator.isValidFilename($0) }
                )
                .autocapitalization(.words)
                .autocorrectionDisabled()
                .accessibilityIdentifier(TestTags.backupNameInput)
            }
        }
        .animation(.default, value: viewModel.cautionState)
    }
}
