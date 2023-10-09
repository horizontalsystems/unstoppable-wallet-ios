import ComponentKit
import SwiftUI
import ThemeKit

struct BackupPasswordView: View {
    @ObservedObject var viewModel: BackupAppViewModel
    @Binding var backupPresented: Bool

    @State var secureLock = true

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                VStack(spacing: .margin32) {
                    Text("backup.password.description".localized)
                        .themeSubhead2()
                        .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))

                    VStack(spacing: .margin16) {
                        InputTextRow {
                            InputTextView(
                                placeholder: "backup.cloud.password.placeholder".localized,
                                text: $viewModel.password,
                                isValidText: { text in PassphraseValidator.validate(text: text) }
                            )
                            .secure($secureLock)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        }
                        .modifier(CautionBorder(cautionState: $viewModel.passwordCautionState))
                        .modifier(CautionPrompt(cautionState: $viewModel.passwordCautionState))

                        InputTextRow {
                            InputTextView(
                                placeholder: "backup.cloud.password.confirm.placeholder".localized,
                                text: $viewModel.confirm,
                                isValidText: { text in PassphraseValidator.validate(text: text) }
                            )
                            .secure($secureLock)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        }
                        .modifier(CautionBorder(cautionState: $viewModel.confirmCautionState))
                        .modifier(CautionPrompt(cautionState: $viewModel.confirmCautionState))
                    }
                    .animation(.default, value: secureLock)

                    HighlightedTextView(text: "backup.password.highlighted_description".localized, style: .warning)
                }
                .animation(.default, value: viewModel.passwordCautionState)
                .animation(.default, value: viewModel.confirmCautionState)
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            } bottomContent: {
                Button(action: {
                    viewModel.onTapSave()
                }) {
                    HStack(spacing: .margin8) {
                        if viewModel.passwordButtonProcessing {
                            ProgressView().progressViewStyle(.circular)
                        }

                        Text("button.save".localized)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(viewModel.passwordButtonDisabled || viewModel.passwordButtonProcessing)
                .animation(.default, value: viewModel.passwordButtonProcessing)
            }
            .sheet(item: $viewModel.sharePresented) { url in
                let completion: UIActivityViewController.CompletionWithItemsHandler = { _, success, _, error in
                    if success {
                        showDone()
                        backupPresented = false
                    }
                    if let error {
                        show(error: error)
                    }
                }
                if #available(iOS 16, *) {
                    ActivityViewController(activityItems: [url], completionWithItemsHandler: completion).presentationDetents([.medium, .large])
                } else {
                    ActivityViewController(activityItems: [url], completionWithItemsHandler: completion)
                }
            }
            .onReceive(viewModel.dismissPublisher) {
                backupPresented = false
            }
            .navigationBarTitle("backup.password.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("button.cancel".localized) {
                    backupPresented = false
                }
            }
        }
    }

    @MainActor
    private func showSuccess() {
        HudHelper.instance.show(banner: .savedToCloud)
    }

    @MainActor
    private func show(error: Error) {
        HudHelper.instance.show(banner: .error(string: error.localizedDescription))
    }

    @MainActor
    func showDone() {
        HudHelper.instance.show(banner: .done)
    }
}
