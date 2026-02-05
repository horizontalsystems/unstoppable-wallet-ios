import SwiftUI

struct BackupNameView: View {
    @ObservedObject var viewModel: BackupAppViewModel
    @Binding var isPresented: Bool

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
                }
            } bottomContent: {
                if viewModel.destination == .cloud && Core.shared.cloudBackupKeyManager.isAvailable {
                    Button(action: {
                        viewModel.onTapSaveBiometric()
                    }) {
                        HStack(spacing: .margin8) {
                            if viewModel.passwordButtonProcessing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                            Text("button.save".localized)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                    .disabled(viewModel.nameCautionState != .none || viewModel.passwordButtonProcessing)
                } else {
                    Button(action: {
                        viewModel.passwordPushed = true
                    }) {
                        Text("button.next".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                    .disabled(viewModel.nameCautionState != .none)
                }
            }
            .navigationTitle("backup_app.backup.name.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $viewModel.passwordPushed) {
                BackupPasswordView(viewModel: viewModel, isPresented: $isPresented)
            }
            .toolbar {
                Button("button.cancel".localized) {
                    isPresented = false
                }
            }
            .toolbarRole(.editor)
            .onReceive(viewModel.dismissPublisher) {
                isPresented = false
            }
        }
    }
}
