import SwiftUI

struct BackupDisclaimerView: View {
    @ObservedObject var viewModel: BackupViewModel
    @Binding var path: NavigationPath

    @State private var termsAccepted: Bool = false

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: .margin32) {
                        HighlightedTextView(text: disclaimerText, style: .warning)

                        ListSection {
                            Cell(
                                left: {
                                    Image.checkbox(active: termsAccepted)
                                },
                                middle: {
                                    MiddleTextIcon(text: ComponentText(text: checkboxText))
                                },
                                action: {
                                    termsAccepted.toggle()
                                }
                            )
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                Button(action: {
                    onNext()
                }) {
                    Text("button.next".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(!termsAccepted)
            }
        }
        .navigationTitle(titleText)
        .toolbar {
            Button("button.cancel".localized) {
                viewModel.cancel()
            }
        }
    }

    private var titleText: String {
        switch viewModel.destination {
        case .cloud:
            return "backup_app.backup.disclaimer.cloud.title".localized
        case .files, .none:
            return "backup_app.backup.disclaimer.file.title".localized
        }
    }

    private var disclaimerText: String {
        switch viewModel.destination {
        case .cloud:
            return "backup_app.backup.disclaimer.cloud.description".localized
        case .files, .none:
            return "backup_app.backup.disclaimer.file.description".localized
        }
    }

    private var checkboxText: String {
        switch viewModel.destination {
        case .cloud:
            return "backup_app.backup.disclaimer.cloud.checkbox_label".localized
        case .files, .none:
            return "backup_app.backup.disclaimer.file.checkbox_label".localized
        }
    }

    private func onNext() {
        path.append(BackupModule.Step.name)
    }
}
